(g => { var h, a, k, p = "The Google Maps JavaScript API", c = "google", l = "importLibrary", q = "__ib__", m = document, b = window; b = b[c] || (b[c] = {}); var d = b.maps || (b.maps = {}), r = new Set, e = new URLSearchParams, u = () => h || (h = new Promise(async (f, n) => { await (a = m.createElement("script")); e.set("libraries", [...r] + ""); for (k in g) e.set(k.replace(/[A-Z]/g, t => "_" + t[0].toLowerCase()), g[k]); e.set("callback", c + ".maps." + q); a.src = `https://maps.${c}apis.com/maps/api/js?` + e; d[q] = f; a.onerror = () => h = n(Error(p + " could not load.")); a.nonce = m.querySelector("script[nonce]")?.nonce || ""; m.head.append(a) })); d[l] ? console.warn(p + " only loads once. Ignoring:", g) : d[l] = (f, ...n) => r.add(f) && u().then(() => d[l](f, ...n)) })
    ({ key: "AIzaSyBJg-GJpfYFVasB5r7kN0yD-WBtCLOcPaM", v: "beta" });


function changeTab(targetTabId) {
    // Deactivate all tabs
    document.querySelectorAll(".tabcontent").forEach(function (tab) {
        tab.classList.remove('active-tab');
        tab.style.display = 'none';
    });
    document.querySelectorAll('.tablink').forEach(function (btn) {
        btn.classList.remove('active-tab');
    });

    if (targetTabId === "tab3")
        startScanning();
    else
        stopScanning();

    // Activate the target tab's content
    const targetTab = document.getElementById(targetTabId);
    targetTab.style.display = 'block';  // Set display to block
    setTimeout(() => {
        targetTab.classList.add('active-tab'); // This will trigger the opacity transition
    }, 10); // Small delay to ensure the block display has rendered in the browser

    // Find the associated button for the tab and mark it as active
    document.querySelector(`.tablink[data-tab="${targetTabId}"]`).classList.add('active-tab');
}

document.querySelectorAll('.tablink').forEach(function (tabButton) {
    tabButton.addEventListener('click', function () {
        changeTab(this.getAttribute('data-tab'));
    });
});

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

async function initMap() {
    // Request needed libraries.
    const { Map } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
    const { LatLng } = await google.maps.importLibrary("core");
    let userLocation = await getUserLocation();
    let center;

    if (userLocation) {
        center = new LatLng(userLocation.latitude, userLocation.longitude);
    } else {
        center = new LatLng(-37.69585780409373, 144.55738418426841); // Default center
    }
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
        zoom: 10,
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
            const lat = parseFloat(e.currentTarget.getAttribute('data-lat'));
            const lng = parseFloat(e.currentTarget.getAttribute('data-lng'));
            const propertyIndex = parseInt(e.currentTarget.getAttribute('data-id'), 10);

            const newCenter = new LatLng(lat, lng);
            map.setCenter(newCenter);

            toggleHighlight(markers[propertyIndex], properties[propertyIndex]);

            changeTab('tab2');
        });
    });

    const markers = [];

    for (const property of properties) {
        const AdvancedMarkerElement = new google.maps.marker.AdvancedMarkerElement({
            map,
            content: buildContent(property),
            position: property.position,
            title: property.description,
        });
        markers.push(AdvancedMarkerElement);

        // Here's where you add the script:
        const contentElement = AdvancedMarkerElement.content;
        if (contentElement.querySelector('.fa-building')) {
            contentElement.classList.add('contains-building');
        }

        // Apply animation to each property marker
        const content = AdvancedMarkerElement.content;
        content.style.opacity = "0";
        content.addEventListener("animationend", (event) => {
            content.classList.remove("drop");
            content.style.opacity = "1";
        });
        const time = 0 + Math.random(); // Optional: random delay for animation
        content.style.setProperty("--delay-time", time + "s");
        intersectionObserver.observe(content);

        AdvancedMarkerElement.addListener("gmp-click", () => {
            toggleHighlight(AdvancedMarkerElement, property);
        });
    }
}

function toggleHighlight(markerView, property) {
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
  <div class="points">${property.points}</div>
    </div>
  <div class="details">
  <div class="details-close">
  <i class="fa fa-times"></i>
    </div>
  <div class="description">${property.description}</div>
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

const properties = [
    {
        address: "1 - 25 Bakery Square, Melton 3337",
        description: "Xplosions Bar & Bowl",
        points: "100 points",
        type: "free",
        position: {
            lat: -37.68393579760413,
            lng: 144.58488634379611,
        },
    },
    {
        address: "190 Duncans Ln, Diggers Rest VIC 3427",
        description: "Animal Land Childrens Farm",
        points: "200 points",
        type: "paid",
        position: {
            lat: -37.63041517779664,
            lng: 144.74600675465328,
        },
    },
];

initMap();

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

function setProgressBarFill(percentage) {
    const progressBar = document.querySelector('.progress-fill');
    progressBar.style.width = `${percentage}%`;
}

// For demonstration, set it to 60%
setProgressBarFill(60);

const targetDate = new Date('November 30, 2023 23:59:59').getTime();
function updateTimer() {
    const now = new Date().getTime();
    const timeDifference = targetDate - now;

    if (timeDifference <= 0) {
        clearInterval(interval);
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

const interval = setInterval(updateTimer, 1000);

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

/*document.getElementById("scan-button").addEventListener("click", () => {
  startScanning();
});*/

/*document.getElementById("stop-button").addEventListener("click", () => {
    stopScanning();
});*/

function startScanning() {
    //document.getElementById("scanner-div").style.display = 'block';
    qrCodeScanner.start(
        { facingMode: "environment" },
        (error) => {
            console.error("QR code scanning failed: ", error);
        },
        onScanSuccess
    ).catch((error) => {
        console.error("QR code scanning failed: ", error);
    });
}

function stopScanning() {
    qrCodeScanner.stop().catch((error) => {
        console.error("Failed to stop QR code scanning: ", error);
    });
}

function onScanSuccess(decodedText, decodedResult) {
    const url = new URL(decodedText);
    console.log("Scan Success!");
    //const imageKey = url.searchParams.get("pet");
    stopScanning();
    changeTab('tab1');
}