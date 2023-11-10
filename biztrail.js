import { initializeApp } from "https://www.gstatic.com/firebasejs/10.5.2/firebase-app.js";
import {
    getAuth,
    createUserWithEmailAndPassword,
    //signInWithPopup,
    signInWithRedirect,
    GoogleAuthProvider,
    onAuthStateChanged,
    signOut,
    fetchSignInMethodsForEmail
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
const provider = new GoogleAuthProvider();
const functions = getFunctions(app, 'australia-southeast1');
const addPoints = httpsCallable(functions, 'addPoints');

// Initialize Firestore
const db = getFirestore(app);

window.addEventListener('load', initializeApplication);

document.addEventListener('DOMContentLoaded', (event) => {
    // Ensure the DOM is fully loaded
    const signupForm = document.getElementById('signup-form');

    if (signupForm) {
        signupForm.addEventListener('submit', async function (e) {
            e.preventDefault(); // This will prevent the default form submission

            const email = signupForm['signup-email'].value; // Replace 'email' with the actual ID or name of your email input field
            const password = signupForm['signup-password'].value; // Replace 'password' with the ID or name of your password input field

            await emailPasswordSignUp(email, password);
        });
    }
    else {
        console.log("signupForm not found");
    }
});


// Listen to authentication state changes
onAuthStateChanged(auth, (user) => {
    if (user) {
        updateUserProfile(user);

        // Reference to the user's document
        const userDocRef = doc(db, 'users', user.uid);

        // Listen to the user's points in Firestore
        onSnapshot(userDocRef, (doc) => {
            if (doc.exists()) {
                const userData = doc.data();
                // Update your text element with the new points
                document.getElementById('pointsElement').textContent = userData.points;
            } else {
                // Handle the case where the user does not exist
                console.log("Document does not exist");
            }
        });
    } else {
        console.log("User is not signed in");
        // Optionally, handle the case where the user is not logged in.
    }
});

document.getElementById("add-points").addEventListener("click", () => {
    // Call the callable function
    addPoints({ points: 50 }).then((result) => {
        console.log(result.data);
    }).catch((error) => {
        console.error(`Error calling function: ${error.message}`);
    });
});

// Update user profile in the UI
function updateUserProfile(user) {
    const userName = user.displayName;
    const userEmail = user.email;
    const userProfilePicture = user.photoURL + "?timestamp=" + new Date().getTime();

    // Clear the srcset attribute to ensure the browser uses the src attribute
    const imgElement = document.getElementById("userProfilePicture");
    imgElement.srcset = '';
    imgElement.sizes = ''; // Also clear sizes if needed
    imgElement.src = userProfilePicture;

    document.getElementById("userName").textContent = userName;
    document.getElementById("userEmail").textContent = userEmail;
}

// Example of email/password sign-up
async function emailPasswordSignUp(email, password) {
    try {
        const signInMethods = await fetchSignInMethodsForEmail(auth, email);
        if (signInMethods.length === 0) {
            // Email not associated with an account, create a new one
            await createUserWithEmailAndPassword(auth, email, password);
            // Continue with the new account creation flow...
        } else {
            console.log("Email already associated with an account");
            // You can prompt the user to sign in using one of the existing methods
        }
    } catch (error) {
        console.error("Error during email/password sign-up", error);
    }
}

// Sign in with Google when the Google login button is clicked
const googleLoginButton1 = document.getElementById("google-login-button-1");
const googleLoginButton2 = document.getElementById("google-login-button-2");

const googleSignIn = () => {
    signInWithRedirect(auth, provider)
        .then((result) => {
            // The signed-in user info is handled by onAuthStateChanged
        })
        .catch((error) => {
            console.error("Authentication error:", error);
            // Handle Errors here.
        });
};

googleLoginButton1.addEventListener("click", googleSignIn);
googleLoginButton2.addEventListener("click", googleSignIn);


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

document.querySelectorAll('.tablink').forEach(function (tabButton) {
    tabButton.addEventListener('click', function () {
        changeTab(this.getAttribute('data-tab'));
    });
});

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

// Define the intersectionObserver outside your map initialization
const intersectionObserver = new IntersectionObserver((entries) => {
    for (const entry of entries) {
        if (entry.isIntersecting) {
            entry.target.classList.add("drop");
            intersectionObserver.unobserve(entry.target);
        }
    }
});

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

    const markers = [];
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

            document.getElementById('max-points').textContent = eventData.maxPoints;

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
                content: buildContent(property),
                position: position,
                title: property.title,
            });

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

function buildContent(property) {
    const content = document.createElement("div");
    content.classList.add("property");
    content.setAttribute("data-type", property.type);
    content.innerHTML = `
  <div class="icon-points-container">
  <div class="icon">
   <i aria-hidden="true" class="fa-solid fa-star"></i>
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

/*async function getDistance() {
  let userLocation = await getUserLocation();
  if (userLocation) {
    var lat = userLocation.latitude;
    var long = userLocation.longitude;    
    var destLat = -37.721858214204175;
    var destLng = 144.67268273280393;    
    var distanceInKm = getDistanceFromLatLonInKm(lat, long, destLat, destLng);
    console.log(distanceInKm);
  }
}
getDistance();*/

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    var R = 6371; // Radius of the Earth in kilometers
    var dLat = deg2rad(lat2 - lat1);
    var dLon = deg2rad(lon2 - lon1);
    var a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    var d = R * c; // Distance in kilometers
    return d;
}

function deg2rad(deg) {
    return deg * (Math.PI / 180);
}

/*const maxPoints = 1000;
let currentPoints = 500;

function addPoints(points) {
    currentPoints += points;
    if (currentPoints >= maxPoints) {
        console.log("Ticket added!");
        currentPoints = currentPoints % maxPoints;
    }
    setProgressBarFill((currentPoints / maxPoints) * 100);
}*/

function setProgressBarFill(percentage) {
    const progressBar = document.querySelector('.progress-fill');
    progressBar.style.width = `${percentage}%`;
}

//addPoints(100);

setProgressBarFill(20);

/**
 * Get user's geolocation coordinates.
 * Returns a LatLng object if successful, otherwise null.
 */
async function getUserLocation() {
    if ("geolocation" in navigator) {
        try {
            const position = await new Promise((resolve, reject) => {
                navigator.geolocation.getCurrentPosition(resolve, reject, {
                    timeout: 10000 // Optional: Set a timeout, e.g., 10 seconds
                });
            });
            return {
                latitude: position.coords.latitude,
                longitude: position.coords.longitude
            };
        } catch (error) {
            console.error("Error obtaining geolocation:", error);
        }
    }
    alert("Geolocation not supported by this browser.");
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