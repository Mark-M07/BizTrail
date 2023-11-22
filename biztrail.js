import { initializeApp } from "https://www.gstatic.com/firebasejs/10.5.2/firebase-app.js";
import {
    getAnalytics,
    logEvent
} from "https://www.gstatic.com/firebasejs/10.5.2/firebase-analytics.js";
import {
    getAuth,
    createUserWithEmailAndPassword,
    signInWithEmailAndPassword,
    signInWithRedirect,
    GoogleAuthProvider,
    OAuthProvider,
    onAuthStateChanged,
    signOut,
    sendPasswordResetEmail,
    sendEmailVerification
} from "https://www.gstatic.com/firebasejs/10.5.2/firebase-auth.js";
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
    ({ key: "AIzaSyCkI7_eaRpS3YcXXt29lsFCdRy4zUZ59yk", v: "beta" });

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyD5AQTiAWxG1viyNpPrdQaCPP2fnmZXgvA",
    authDomain: "biz-trail.firebaseapp.com",
    projectId: "biz-trail",
    storageBucket: "biz-trail.appspot.com",
    messagingSenderId: "972839717909",
    appId: "1:972839717909:web:3283259443b400e13e521c",
    measurementId: "G-WGLMV325KN"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);
auth.languageCode = 'en';
const googleProvider = new GoogleAuthProvider();
const appleProvider = new OAuthProvider('apple.com');
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

document.addEventListener('DOMContentLoaded', (event) => {
    // Ensure the DOM is fully loaded
    const eventName = document.getElementById('event-name').dataset.eventName;
    const signupForm = document.getElementById('signup-form');
    const loginForm = document.getElementById('login-form');
    const accountForm = document.getElementById('account-form');
    const codeForm = document.getElementById('code-form');
    const codeEntryModal = document.getElementById('code-entry');
    const eventPoints = document.getElementById("event-points");
    const eventTickets = document.getElementById("event-tickets");
    const pointsRemaining = document.getElementById("points-remaining");
    const progressFill = document.getElementById("progress-fill");
    const activityLogDiv = document.getElementById("activity-log");
    const scanResult = document.getElementById("scan-result");
    const scanLoading = document.getElementById("scan-loading");
    const imageSuccess = document.getElementById("image-success");
    const imageFail = document.getElementById("image-fail");
    const scanMessage = document.getElementById("scan-message");
    const spans = document.querySelectorAll('.text-countdown span');
    const qrCodeScanner = new Html5Qrcode('scanner');
    const markers = [];
    let isScannerActive = false;
    let isScannerTransitioning = false;
    let interval;
    let currentlyHighlighted = null;

    document.getElementById("points-button").addEventListener("click", () => {
        changeTab('tab5');
    });

    document.getElementById("countdown-button").addEventListener("click", () => {
        changeTab('tab4');
    });

    document.getElementById("tickets-button").addEventListener("click", () => {
        changeTab('tab4');
    });

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

    codeForm.addEventListener('submit', async function (e) {
        e.preventDefault(); // Prevent the default form submission
        e.stopPropagation(); // Stop event propagation

        const code = codeForm['code-word'].value;

        codeEntryModal.style.display = 'none';
        changeTab('tab1');
        scanResult.style.display = 'flex';
        checkLocation(code);
        logEvent(analytics, 'code_entry', { code: code });
    });

    document.getElementById("reset-password").addEventListener("click", () => {
        const email = loginForm['login-email'].value;
        passwordReset(email);
    });

    // Add event listeners to both Google login buttons
    document.querySelectorAll("[id^='google-login-button-']").forEach(button => {
        button.addEventListener("click", googleSignIn);
    });

    // Add event listeners to both Apple login buttons
    document.querySelectorAll("[id^='apple-login-button-']").forEach(button => {
        button.addEventListener("click", appleSignIn);
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

    async function initializeApplication() {
        // Fetch and handle event-related data
        try {
            const eventName = document.getElementById('event-name').dataset.eventName;
            const eventData = await fetchEvent(eventName);
            let mapGenerated = false;

            if (eventData) {
                const url = new URL(window.location.href);

                const loc = url.searchParams.get("loc");
                if (loc) {
                    changeTab('tab1');
                    scanResult.style.display = 'flex';
                    checkLocation(loc);
                }

                const howItWorks = url.searchParams.get("how-it-works");
                if (howItWorks) {
                    document.getElementById("how-it-works").style.display = 'flex';
                }

                url.searchParams.forEach((value, paramName) => {
                    logEvent(analytics, 'url_query', { param: paramName, value: value });

                    url.searchParams.delete(paramName);
                });

                // Update the URL without query parameters
                window.history.replaceState({}, '', url);

                // Countdown timer
                initializeCountdown(eventData.drawTime);

                // Set draw time
                const drawTimeElement = document.getElementById('draw-time');
                const formattedDate = formatDateForDisplay(eventData.drawTime);
                drawTimeElement.innerHTML = formattedDate;

                // Listen to authentication state changes
                onAuthStateChanged(auth, async (user) => {
                    if (user && user.emailVerified) {
                        // Update UI for logged-in state
                        document.getElementById("sign-up").style.display = 'none';
                        document.getElementById("log-in").style.display = 'none';
                        document.getElementById("logged-out").style.display = 'none';
                        document.getElementById("logged-in").style.display = 'flex';

                        // Set up real-time updates for user's account data
                        const userDocRef = doc(db, 'users', user.uid);
                        onSnapshot(userDocRef, (doc) => {
                            if (doc.exists()) {
                                const userData = doc.data();
                                updateUserProfileUI(user, userData);
                            }
                        });

                        // Generate map for signed-in user
                        if (!mapGenerated) {
                            const locations = await getDocs(collection(db, "events", eventName, "locations"));
                            await generateMap(locations);
                            mapGenerated = true;
                        }

                        // Set up real-time updates for user's event data
                        const userEventDocRef = doc(db, 'users', user.uid, 'events', eventName);
                        onSnapshot(userEventDocRef, (doc) => {
                            if (doc.exists()) {
                                const userEventData = doc.data();
                                updateUserEventUI(userEventData);
                                updateVisitedMarkers(userEventData.locations || []);
                            }
                        });
                    }
                });

                // Generate map for non-signed-in user
                if (!mapGenerated) {
                    if (!auth.currentUser || !auth.currentUser.emailVerified) {
                        const locations = await getDocs(collection(db, "events", eventName, "locations"));
                        await generateMap(locations);
                        mapGenerated = true;
                    }
                }
            }

        } catch (error) {
            console.error("Error initializing application:", error);
        }
    }

    async function fetchEvent(eventName) {
        const eventDoc = await getDoc(doc(db, "events", eventName));
        if (!eventDoc.exists()) {
            console.log(`${eventName} event document not found!`);
            return null;
        }
        return eventDoc.data();
    }

    function formatDateForDisplay(timestamp) {
        // Convert Firestore Timestamp to JavaScript Date object
        const date = timestamp.toDate();

        const dateOptions = { year: 'numeric', month: 'long', day: 'numeric' };
        const timeOptions = { hour: 'numeric', minute: 'numeric', hour12: true };

        const formattedDate = date.toLocaleString('en-US', dateOptions);
        const formattedTime = "at " + date.toLocaleString('en-US', timeOptions);

        return `${formattedDate}<br>${formattedTime}`;
    }

    initializeApplication();

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
        eventPoints.textContent = userEventData.points;
        eventTickets.textContent = userEventData.tickets;
        pointsRemaining.textContent = 2000 - userEventData.points;
        progressFill.style.width = `${(userEventData.points / 2000) * 100}%`;

        // Update the activity log
        activityLogDiv.innerHTML = ''; // Clear existing content

        if (userEventData.activityLog && userEventData.activityLog.length > 0) {
            userEventData.activityLog.slice().reverse().forEach(logEntry => {
                // Split the log entry into parts using the '~' delimiter
                const [locationPart, pointsPart, timeStampPart] = logEntry.split('~');

                // Create div for log entry
                const logDiv = document.createElement('div');
                logDiv.classList.add('log-entry');

                // Create span for location
                const locationSpan = document.createElement('span');
                locationSpan.classList.add('location-text');
                locationSpan.textContent = locationPart;
                logDiv.appendChild(locationSpan);

                // Create span for points
                const pointsSpan = document.createElement('span');
                pointsSpan.classList.add('points-text');
                pointsSpan.textContent = ' ' + pointsPart;
                logDiv.appendChild(pointsSpan);

                // Append the timestamp
                logDiv.append(timeStampPart);

                // Append the log entry to the log container
                activityLogDiv.appendChild(logDiv);
            });
        } else {
            const logDiv = document.createElement('div');
            logDiv.classList.add('log-entry');
            const locationSpan = document.createElement('span');
            locationSpan.classList.add('location-text');
            locationSpan.textContent = 'No activity recorded.';
            logDiv.appendChild(locationSpan);
            activityLogDiv.appendChild(logDiv);
        }
    }

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
            if (!isScannerActive && !isScannerTransitioning) {
                startScanning();
            }
        }
        else if (isScannerActive && !isScannerTransitioning) {
            stopScanning();
        }

        // Activate the target tab's content
        const targetTab = document.getElementById(targetTabId);
        if (!targetTab) {
            console.error("changeTab - targetTab not found:", targetTabId);
            return;
        }

        targetTab.style.display = 'block';  // Set display to block
        setTimeout(() => {
            targetTab.classList.add('active-tab'); // This will trigger the opacity transition
        }, 10); // Small delay to ensure the block display has rendered in the browser

        // Find the associated button for the tab and mark it as active
        const button = document.querySelector(`.tablink[data-tab="${targetTabId}"]`);
        if (button) {
            button.classList.add('active-tab');
        } else {
            console.error("changeTab - associated button not found for tab:", targetTabId);
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

    async function generateMap(locations) {
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

    function buildContent(property) {
        const content = document.createElement("div");
        content.classList.add("property");
        content.setAttribute("data-type", property.type);
        const iconClass = 'fa-star';
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
                    <a href="https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(property.title)}" target="_blank" rel="noopener noreferrer">More Info</a>
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
        markers.forEach(marker => {
            if (visitedLocations.includes(marker.locationId)) {
                const contentElement = marker.content;
                if (contentElement) {
                    // Update the data-type attribute
                    contentElement.setAttribute("data-type", 'visited');

                    // Update the SVG icon if it exists
                    const iconSVG = contentElement.querySelector('.icon svg');
                    if (iconSVG) {
                        iconSVG.setAttribute('data-icon', 'circle-check');

                        // If needed, update the style (e.g., from regular to solid)
                        //iconSVG.setAttribute('data-prefix', 'fas'); // 'fas' for solid, 'far' for regular
                    }

                    // Update the <i> tag icon if it exists
                    const iconElement = contentElement.querySelector('.icon i');
                    if (iconElement) {
                        iconElement.className = 'fa-regular fa-circle-check';
                    }
                }
            }
        });
    }

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

    function startScanning() {
        isScannerTransitioning = true;
        qrCodeScanner.start(
            { facingMode: "environment" },
            (error) => {
                console.error("Failed to start QR code scanning: ", error);
            },
            onScanSuccess
        ).then(() => {
            isScannerActive = true;
            isScannerTransitioning = false;
        }).catch((error) => {
            console.error("Failed to start QR code scanning: ", error);
            isScannerTransitioning = false;
        });
    }

    function stopScanning() {
        isScannerTransitioning = true;
        qrCodeScanner.stop()
            .then(() => {
                isScannerActive = false;
                isScannerTransitioning = false;
            })
            .catch((error) => {
                console.error("Failed to stop QR code scanning: ", error);
                isScannerTransitioning = false;
            });
    }

    function onScanSuccess(decodedText, decodedResult) {
        stopScanning();
        try {
            const url = new URL(decodedText);
            const loc = url.searchParams.get("loc");
            if (loc) {
                checkLocation(loc);
                logEvent(analytics, 'qr_scan', {
                    scan_result: "success",
                    scan_decoded_text: decodedText,
                    scan_message: loc
                });
            } else {
                invalidQR();
                logEvent(analytics, 'qr_scan', {
                    scan_result: fail,
                    scan_decoded_text: decodedText,
                    scan_message: "loc is null."
                });
            }
        } catch (error) {
            console.error("Error parsing URL:", error);
            invalidQR();
            logEvent(analytics, 'qr_scan', {
                scan_result: "fail",
                scan_decoded_text: decodedText,
                scan_message: error.message
            });
        }
        scanResult.style.display = 'flex';
        changeTab('tab1');
    }

    function invalidQR() {
        scanLoading.style.display = 'none';
        imageSuccess.style.display = 'none';
        imageFail.style.display = 'flex';
        scanMessage.style.display = 'block';
        scanMessage.textContent = "Invalid QR or code word.";
        scanMessage.style.backgroundColor = '#ffdede';
    }

    async function checkLocation(loc) {
        scanMessage.style.display = 'block';
        scanLoading.style.display = 'block';
        imageSuccess.style.display = 'none';
        imageFail.style.display = 'none';
        scanMessage.textContent = "Checking QR code...";
        scanMessage.style.backgroundColor = '#e0e0e0';
        try {
            let userLocation = await getUserLocation();
            if (userLocation) {
                const result = await addPoints({
                    eventName: eventName,
                    locationId: loc,
                    userLat: userLocation.latitude,
                    userLng: userLocation.longitude,
                    userAccuracy: userLocation.accuracy
                });
                logEvent(analytics, 'collect_success', {
                    collect_location_ID: loc,
                    collect_result_data: result.data
                });
                scanLoading.style.display = 'none';
                imageSuccess.style.display = 'flex';
                scanMessage.textContent = result.data;
                scanMessage.style.backgroundColor = '#deffde';
            } else {
                scanLoading.style.display = 'none';
                imageFail.style.display = 'flex';
                logEvent(analytics, 'collect_fail', {
                    collect_location_ID: loc,
                    collect_error_message: "Unable to retrieve user location."
                });
                scanMessage.textContent = "Unable to retrieve user location.";
                scanMessage.style.backgroundColor = '#ffdede';
            }
        } catch (error) {
            //console.error("Error adding points:", error);
            scanLoading.style.display = 'none';
            imageFail.style.display = 'flex';
            logEvent(analytics, 'collect_fail', {
                collect_location_ID: loc,
                collect_error_message: error.message
            });
            scanMessage.textContent = error.message;
            scanMessage.style.backgroundColor = '#ffdede';
        }
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

// Handle Apple sign-in for both buttons
const appleSignIn = async () => {
    try {
        await signInWithRedirect(auth, appleProvider);
        // The signed-in user info is handled by onAuthStateChanged
    } catch (error) {

        console.error("Authentication error:", error);
        // Handle Errors here.
    }
};