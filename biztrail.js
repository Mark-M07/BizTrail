import { initializeApp } from "https://www.gstatic.com/firebasejs/10.5.2/firebase-app.js";
import {
    getAuth,
    createUserWithEmailAndPassword,
    signInWithEmailAndPassword,
    signInWithRedirect,
    GoogleAuthProvider,
    onAuthStateChanged,
    signOut,
    sendPasswordResetEmail,
    sendEmailVerification
} from "https://www.gstatic.com/firebasejs/10.5.2/firebase-auth.js";
// Import the Firebase Functions SDK
import {
    getFunctions,
    httpsCallable
} from "https://www.gstatic.com/firebasejs/10.5.2/firebase-functions.js";
import {
    getFirestore,
    doc,
    onSnapshot,
    collection,
    getDoc,
    getDocs
} from "https://www.gstatic.com/firebasejs/10.5.2/firebase-firestore.js";

(g => { var h, a, k, p = "The Google Maps JavaScript API", c = "google", l = "importLibrary", q = "__ib__", m = document, b = window; b = b[c] || (b[c] = {}); var d = b.maps || (b.maps = {}), r = new Set, e = new URLSearchParams, u = () => h || (h = new Promise(async (f, n) => { await (a = m.createElement("script")); e.set("libraries", [...r] + ""); for (k in g) e.set(k.replace(/[A-Z]/g, t => "_" + t[0].toLowerCase()), g[k]); e.set("callback", c + ".maps." + q); a.src = `https://maps.${c}apis.com/maps/api/js?` + e; d[q] = f; a.onerror = () => h = n(Error(p + " could not load.")); a.nonce = m.querySelector("script[nonce]")?.nonce || ""; m.head.append(a) })); d[l] ? console.warn(p + " only loads once. Ignoring:", g) : d[l] = (f, ...n) => r.add(f) && u().then(() => d[l](f, ...n)) })
    ({ key: "AIzaSyBJg-GJpfYFVasB5r7kN0yD-WBtCLOcPaM", v: "beta" });

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyD5AQTiAWxG1viyNpPrdQaCPP2fnmZXgvA",
    authDomain: "biz-trail.firebaseapp.com",
    projectId: "biz-trail",
    storageBucket: "biz-trail.appspot.com",
    messagingSenderId: "972839717909",
    appId: "1:972839717909:web:3283259443b400e13e521c"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
auth.languageCode = 'en';
const googleProvider = new GoogleAuthProvider();
const functions = getFunctions(app, 'australia-southeast1');
const updateUserProfile = httpsCallable(functions, 'updateUserProfile');
const addPoints = httpsCallable(functions, 'addPoints');

// Initialize Firestore
const db = getFirestore(app);

// Define the intersectionObserver outside your map initialization
const intersectionObserver = new IntersectionObserver((entries) => {
    for (const entry of entries) {
        if (entry.isIntersecting) {
            entry.target.classList.add("drop");
            intersectionObserver.unobserve(entry.target);
        }
    }
});

//window.addEventListener('load', initializeApplication);

document.addEventListener('DOMContentLoaded', (event) => {
    // Ensure the DOM is fully loaded
    const signupForm = document.getElementById('signup-form');
    const loginForm = document.getElementById('login-form');
    const accountForm = document.getElementById('account-form');
    const markers = [];

    initializeApplication();

    signupForm.addEventListener('submit', async function (e) {
        e.preventDefault(); // Prevent the default form submission
        e.stopPropagation(); // Stop event propagation

        const name = signupForm['signup-name'].value;
        const email = signupForm['signup-email'].value;
        const password = signupForm['signup-password'].value;

        await emailPasswordSignUp(name, email, password);
    });

    loginForm.addEventListener('submit', async function (e) {
        e.preventDefault(); // Prevent the default form submission
        e.stopPropagation(); // Stop event propagation

        const email = loginForm['login-email'].value;
        const password = loginForm['login-password'].value;

        emailSignIn(email, password);
    });
    document.getElementById("reset-password").addEventListener("click", () => {
        const email = loginForm['login-email'].value;
        passwordReset(email);
    });

    // Add event listeners to both Google login buttons
    document.querySelectorAll("[id^='google-login-button-']").forEach(button => {
        button.addEventListener("click", googleSignIn);
    });

    // Logout user when the logout button is clicked
    const logoutButton = document.getElementById("logout-button");
    logoutButton.addEventListener("click", () => {
        signOut(auth).then(() => {
            // Reload the current URL
            //window.location.reload();
            // Redirect to the base domain URL
            window.location.href = "/";
        }).catch((error) => {
            console.error("Sign out error:", error);
        });
    });

    // Listen to authentication state changes
    onAuthStateChanged(auth, async (user) => {
        if (user) {
            if (user.emailVerified) {
                document.getElementById("sign-up").style.display = 'none';
                document.getElementById("log-in").style.display = 'none';
                document.getElementById("logged-out").style.display = 'none';
                document.getElementById("logged-in").style.display = 'flex';

                // Reference to the user's document
                const userDocRef = doc(db, 'users', user.uid);

                // Listen to changes to the user's document
                onSnapshot(userDocRef, (doc) => {
                    if (doc.exists()) {
                        const userData = doc.data();
                        updateUserProfileUI(user, userData);
                    }
                });

                // Define the event name you want to listen to
                const eventName = "businessKyneton";

                // Reference to the user's event document
                const userEventDocRef = doc(db, 'users', user.uid, 'events', eventName);

                // Listen to changes to the user's event document
                onSnapshot(userEventDocRef, (doc) => {
                    if (doc.exists()) {
                        const userEventData = doc.data();
                        updateUserEventUI(userEventData);
                        updateVisitedMarkers(userEventData.locations || []);
                    }
                });
            }
        }
    });

    // Update user profile in the UI
    function updateUserProfileUI(user, userData) {
        // Update the UI with user data
        const imgElement = document.getElementById("userProfilePicture");
        const letterElement = document.getElementById("userProfileLetter");
        const userProfilePicture = user.photoURL;
        const displayName = userData.displayName || "";

        if (!userProfilePicture) {
            imgElement.style.display = 'none';
            letterElement.textContent = (displayName.charAt(0)).toUpperCase();
            letterElement.style.display = 'flex';
        }
        else {
            letterElement.style.display = 'none';
            imgElement.srcset = '';
            imgElement.sizes = '';
            imgElement.src = userProfilePicture + "?timestamp=" + new Date().getTime();
            imgElement.style.display = 'flex';
        }

        document.getElementById("account-email").textContent = userData.email || "";
        accountForm['account-name'].value = displayName;
        accountForm['account-phone'].value = userData.phoneNumber || "";
    }

    // Update user event in the UI
    function updateUserEventUI(userEventData) {
        // Update the UI with user event data
        document.getElementById("event-points").textContent = userEventData.points;
        document.getElementById("event-tickets").textContent = userEventData.tickets;
        document.getElementById("points-remaining").textContent = 2000 - userEventData.points;
        document.getElementById("progress-fill").style.width = `${(userEventData.points / 2000) * 100}%`;
    }

    accountForm.addEventListener('submit', async function (e) {
        e.preventDefault(); // Prevent the default form submission
        e.stopPropagation(); // Stop event propagation

        const name = accountForm['account-name'].value;
        const phone = accountForm['account-phone'].value;

        const accountMessage = document.getElementById("account-message");
        accountMessage.style.display = 'block';
        try {
            accountMessage.textContent = "Attempting to update account details.";
            accountMessage.style.backgroundColor = '#e0e0e0';
            await updateUserProfile({ name: name, phone: phone });
            // Handle successful update
            accountMessage.textContent = "Account details updated.";
            accountMessage.style.backgroundColor = '#deffde';
        } catch (error) {
            // Handle errors
            console.error("Error updating profile:", error);
            accountMessage.textContent = "Error updating profile.";
            accountMessage.style.backgroundColor = '#ffdede';
        }
    });

    const addPointsButton = document.getElementById('add-points');

    addPointsButton.addEventListener('click', async function () {
        try {
            let userLocation = await getUserLocation();
            if (userLocation) {
                console.log("Sending points data");
                console.log(`Lat: ${userLocation.latitude}, Long: ${userLocation.longitude}`);
                const result = await addPoints({
                    eventName: "businessKyneton",
                    locationId: "sonderSites",
                    userLat: userLocation.latitude,
                    userLng: userLocation.longitude,
                    userAccuracy: userLocation.accuracy
                });

                // Handle the response from your Cloud Function
                console.log("Points added:", result);
            } else {
                console.log("Unable to retrieve user location");
                // Handle the case where user location couldn't be retrieved
            }
        } catch (error) {
            console.error("Error adding points:", error);
            // Handle any errors that occur during the points addition process
        }
    });

    document.querySelectorAll('.tablink').forEach(function (tabButton) {
        tabButton.addEventListener('click', function () {
            changeTab(this.getAttribute('data-tab'));
        });
    });

    async function emailPasswordSignUp(name, email, password) {
        const signupMessage = document.getElementById("signup-message");
        signupMessage.style.display = 'block';

        try {
            signupMessage.textContent = "Attempting to create new account.";
            signupMessage.style.backgroundColor = '#e0e0e0';

            // Create the user account
            const userCredential = await createUserWithEmailAndPassword(auth, email, password);

            // Send verification email
            if (userCredential.user) {
                await sendEmailVerification(userCredential.user);
                signupMessage.textContent = "Account created. Verification email sent.";
                signupMessage.style.backgroundColor = '#deffde';

                // Update the user profile
                try {
                    const result = await updateUserProfile({ name: name, phone: "" });
                    console.log(result.data);
                } catch (error) {
                    console.error("Error updating profile:", error);
                }

                // Sign out the user
                await signOut(auth);
            }
        } catch (error) {
            if (error.code === 'auth/email-already-in-use') {
                signupMessage.textContent = "An account with this email already exists.";
                signupMessage.style.backgroundColor = '#ffdede';
            } else {
                signupMessage.textContent = error.message;
                signupMessage.style.backgroundColor = '#ffdede';
            }
        }
    }

    function changeTab(targetTabId) {
        // Deactivate all tabs
        document.querySelectorAll(".tabcontent").forEach(function (tab) {
            tab.classList.remove('active-tab');
            tab.style.display = 'none';
        });
        document.querySelectorAll('.tablink').forEach(function (btn) {
            btn.classList.remove('active-tab');
        });

        if (targetTabId === "tab3") {
            startScanning();
        }
        else if (isScannerActive) {
            stopScanning();
        }

        // Activate the target tab's content
        const targetTab = document.getElementById(targetTabId);
        targetTab.style.display = 'block';  // Set display to block
        setTimeout(() => {
            targetTab.classList.add('active-tab'); // This will trigger the opacity transition
        }, 10); // Small delay to ensure the block display has rendered in the browser

        // Find the associated button for the tab and mark it as active
        document.querySelector(`.tablink[data-tab="${targetTabId}"]`).classList.add('active-tab');
    }

    let currentlyHighlighted = null;

    async function initializeApplication() {
        // Request needed libraries.
        const { Map } = await google.maps.importLibrary("maps");
        const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
        const { LatLng } = await google.maps.importLibrary("core");
        //let userLocation = await getUserLocation();
        let center;
        center = new LatLng(-37.24909666554568, 144.45323073712373); // Default center of Kyneton
        /*if (userLocation) {
            center = new LatLng(userLocation.latitude, userLocation.longitude);
        } else {
            center = new LatLng(-37.69585780409373, 144.55738418426841); // Default center
        }*/
        const mapStyles = [
            {
                featureType: 'poi',  // Points of interest
                stylers: [{ visibility: 'off' }]  // Hide them
            },
            {
                featureType: 'transit',  // Public transit options like bus stops and subway stations
                stylers: [{ visibility: 'off' }]  // Hide them
            },
            {
                featureType: 'road',
                elementType: 'labels.icon',
                stylers: [{ visibility: 'off' }]  // Hide road icons
            },
        ];
        const styledMap = new google.maps.StyledMapType(mapStyles, { name: "Styled Map" });
        const map = new Map(document.getElementById("map"), {
            zoom: 15,
            center,
            mapId: "4504f8b37365c3d0",
            // Control options
            zoomControl: false, // hides the zoom controls
            mapTypeControl: false, // hides the map type (e.g., 'Map', 'Satellite') controls
            scaleControl: false, // hides the scale control
            streetViewControl: false, // hides the Street View control
            rotateControl: false, // hides the rotate control
            fullscreenControl: false // hides the fullscreen control
        });

        map.mapTypes.set('styled_map', styledMap);
        map.setMapTypeId('styled_map');

        document.querySelectorAll('.featured').forEach(btn => {
            btn.addEventListener('click', function (e) {
                const propertyIndex = parseInt(e.currentTarget.getAttribute('data-id'), 10);

                const marker = markers[propertyIndex];

                map.setCenter(marker.position);

                toggleHighlight(marker);

                changeTab('tab2');
            });
        });


        let interval;
        const eventName = document.getElementById('event-name').dataset.eventName;
        fetchEvent(eventName);

        async function fetchEvent(eventName) {
            try {
                // Fetch event document first
                const eventDoc = await getDoc(doc(db, "events", eventName));
                if (!eventDoc.exists()) {
                    console.log(`${eventName} 'event' document found!`);
                    return;
                }

                const eventData = eventDoc.data();

                // Initialize the countdown timer
                initializeCountdown(eventData.drawTime);

                // More code can go here where we might need eventData

                // Generate markers for the event
                const locations = await getDocs(collection(db, "events", eventName, "locations"));
                generateEventMarkers(locations);
            } catch (error) {
                console.error("Error getting documents from Firestore: ", error);
            }
        }

        function initializeCountdown(drawTime) {
            const targetDate = drawTime.toDate().getTime();

            function updateTimer() {
                const now = new Date().getTime();
                const timeDifference = targetDate - now;

                if (timeDifference <= 0) {
                    clearInterval(interval);
                    // Perform additional actions if needed when the countdown ends
                    return;
                }

                const days = Math.floor(timeDifference / (1000 * 60 * 60 * 24));
                const hours = Math.floor((timeDifference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                const minutes = Math.floor((timeDifference % (1000 * 60 * 60)) / (1000 * 60));
                const seconds = Math.floor((timeDifference % (1000 * 60)) / 1000);

                // Assuming your spans are in order, we'll update them
                const spans = document.querySelectorAll('.text-countdown span');
                spans[0].textContent = Math.floor(days / 10);
                spans[1].textContent = days % 10;
                spans[2].textContent = Math.floor(hours / 10);
                spans[3].textContent = hours % 10;
                spans[4].textContent = Math.floor(minutes / 10);
                spans[5].textContent = minutes % 10;
                spans[6].textContent = Math.floor(seconds / 10);
                spans[7].textContent = seconds % 10;
            }

            // Start the timer
            updateTimer(); // Run it once to avoid initial delay
            interval = setInterval(updateTimer, 1000); // Now interval is correctly scoped
        }

        function generateEventMarkers(locations) {
            locations.forEach((doc) => {
                const property = doc.data();
                const firestorePosition = property.position;
                const position = new google.maps.LatLng(firestorePosition._lat, firestorePosition._long);
                const Marker = new AdvancedMarkerElement({
                    map,
                    content: buildContent(property, false),
                    position: position,
                    title: property.title,
                });

                Marker.locationId = doc.id;
                Marker.propertyData = property;
                markers.push(Marker);

                // Here's where you add the script:
                const contentElement = Marker.content;
                if (contentElement.querySelector('.fa-building')) {
                    contentElement.classList.add('contains-building');
                }

                // Apply animation to each property marker
                const content = Marker.content;
                content.style.opacity = "0";
                content.addEventListener("animationend", (event) => {
                    content.classList.remove("drop");
                    content.style.opacity = "1";
                });
                const time = 0 + Math.random(); // Optional: random delay for animation
                content.style.setProperty("--delay-time", time + "s");
                intersectionObserver.observe(content);

                Marker.addListener("gmp-click", () => {
                    toggleHighlight(Marker);
                });
            });
        }
    }

    function toggleHighlight(markerView) {
        // If there's a currently highlighted marker, remove its highlight.
        if (currentlyHighlighted && currentlyHighlighted !== markerView) {
            currentlyHighlighted.content.classList.remove("highlight");
            currentlyHighlighted.zIndex = null;
        }
        if (markerView !== currentlyHighlighted) {
            markerView.content.classList.add("highlight");
            markerView.zIndex = 1;
            currentlyHighlighted = markerView;
        }
    }

    function updateVisitedMarkers(visitedLocations) {
        console.log("Test 0");
        markers.forEach(marker => {
            console.log("Test 1");
            if (visitedLocations.includes(marker.locationId)) {
                // Update the marker content for visited location
                console.log("Test 2");
                const newContent = buildContent(marker.propertyData, true);
                if (marker.content) {
                    marker.content.innerHTML = newContent.innerHTML;
                    console.log("Test 3");
                }
            }
        });
    }

    function buildContent(property, isVisited) {
        const content = document.createElement("div");
        content.classList.add("property");
        content.setAttribute("data-type", property.type);
        const iconClass = isVisited ? 'fa-circle-check' : 'fa-star';
        content.innerHTML = `
      <div class="icon-points-container">
      <div class="icon">
      <i aria-hidden="true" class="fa-regular ${iconClass}"></i>
        </div>
        <div class="points">${property.points} points</div>
        </div>
      <div class="details">
      <div class="details-close">
      <i class="fa fa-times"></i>
        </div>
      <div class="title">${property.title}</div>
      <div class="address">${property.address}</div>
      
      <div class="features">
      <div>
      <i aria-hidden="true" class="fa-regular fa-circle-question" title="More Info"></i>
      <span class="fa-sr-only">More Info</span>
      <span>More Info</span>
        </div>
      <div class="direction-link">
      <i aria-hidden="true" class="fa-solid fa-route" title="Directions"></i>
      <span class="fa-sr-only">Directions</span>
      <a href="https://www.google.com/maps/dir//${encodeURIComponent(property.address)}" target="_blank" rel="noopener noreferrer">Directions</a>
        </div>
        </div>
        </div>
      `;
        const closeButton = content.querySelector('.details-close');
        closeButton.addEventListener('click', (event) => {
            if (currentlyHighlighted) {
                currentlyHighlighted.content.classList.remove("highlight");
                currentlyHighlighted.zIndex = null;
                currentlyHighlighted = null;
            }
            event.stopPropagation();
        });
        return content;
    }
});

const passwordReset = async (email) => {
    const loginMessage = document.getElementById("login-message");
    loginMessage.style.display = 'block';
    try {
        loginMessage.textContent = "Sending password reset email.";
        loginMessage.style.backgroundColor = '#e0e0e0';
        await sendPasswordResetEmail(auth, email);
        loginMessage.textContent = "Password reset email sent.";
        loginMessage.style.backgroundColor = '#deffde';
    } catch (error) {
        console.error("Error sending password reset", error);
        loginMessage.textContent = "Error sending password reset.";
        loginMessage.style.backgroundColor = '#ffdede';
    }
};

// Handle email sign-in
const emailSignIn = async (email, password) => {
    const loginMessage = document.getElementById("login-message");
    loginMessage.style.display = 'block';

    try {
        loginMessage.textContent = "Attempting sign in.";
        loginMessage.style.backgroundColor = '#e0e0e0';

        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        if (userCredential.user) {
            if (!userCredential.user.emailVerified) {
                // Email is not verified
                await signOut(auth); // Sign out the user
                loginMessage.textContent = "Please verify your email address to log in.";
                loginMessage.style.backgroundColor = '#ffdede';
            } else {
                // Email is verified, user can proceed
                loginMessage.textContent = "Sign in successful.";
                loginMessage.style.backgroundColor = '#deffde';
                // The signed-in user info is handled by onAuthStateChanged
            }
        }
    } catch (error) {
        console.error("Authentication error:", error);
        loginMessage.textContent = "Login Failed. Incorrect Email Address or Password.";
        loginMessage.style.backgroundColor = '#ffdede';
    }
};


// Handle Google sign-in for both buttons
const googleSignIn = async () => {
    try {
        await signInWithRedirect(auth, googleProvider);
        // The signed-in user info is handled by onAuthStateChanged
    } catch (error) {

        console.error("Authentication error:", error);
        // Handle Errors here.
    }
};

/**
 * Get user's geolocation coordinates.
 * Returns a LatLng object if successful, otherwise null.
 */
async function getUserLocation() {
    if ("geolocation" in navigator) {
        const options = {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 0
        };

        try {
            const position = await new Promise((resolve, reject) => {
                navigator.geolocation.getCurrentPosition(resolve, reject, options);
            });
            return {
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
                accuracy: position.coords.accuracy // Include accuracy
            };
        } catch (error) {
            console.error("Error obtaining geolocation:", error);
        }
    } else {
        alert("Geolocation not supported by this browser.");
    }
    return null;
}

const qrCodeScanner = new Html5Qrcode('scanner');
let isScannerActive = false;

function startScanning() {
    qrCodeScanner.start(
        { facingMode: "environment" },
        (error) => {
            console.error("QR code scanning failed: ", error);
        },
        onScanSuccess
    ).then(() => {
        isScannerActive = true;
    }).catch((error) => {
        console.error("QR code scanning failed: ", error);
    });
}

function stopScanning() {
    qrCodeScanner.stop()
        .then(() => {
            isScannerActive = false;
        })
        .catch((error) => {
            console.error("Failed to stop QR code scanning: ", error);
        });
}

function onScanSuccess(decodedText, decodedResult) {
    const url = new URL(decodedText);
    console.log(url);
    //const imageKey = url.searchParams.get("pet");
    changeTab('tab1'); // Changing tab automatically stops the scanning
    //addPoints(150);
}