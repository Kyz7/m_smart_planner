import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/place.dart';

class MapWidget extends StatefulWidget {
  final Place center;
  final List<Place> markers;
  final double zoom;

  const MapWidget({
    Key? key,
    required this.center,
    this.markers = const [],
    this.zoom = 13.0,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_generateMapHtml());
  }

  String _generateMapHtml() {
    final centerLat = widget.center.lat;
    final centerLng = widget.center.lng;
    final zoom = widget.zoom;

    // Generate markers JavaScript
    String markersJs = '';
    for (int i = 0; i < widget.markers.length; i++) {
      final marker = widget.markers[i];
      markersJs += '''
        L.marker([${marker.lat}, ${marker.lng}], {
          icon: customIcon
        }).addTo(map)
         .bindPopup(\`
           <div style="text-align: center; font-family: Arial, sans-serif;">
             <h4 style="margin: 0 0 8px 0; color: #2563EB;">${marker.name}</h4>
             <p style="margin: 0 0 8px 0; font-size: 12px; color: #666;">${marker.address}</p>
             <div style="display: flex; align-items: center; justify-content: center; gap: 4px;">
               <span style="color: #f59e0b;">★</span>
               <span style="font-weight: bold; color: #333;">${marker.rating}</span>
             </div>
           </div>
         \`)
         .openPopup();
      ''';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Map Widget</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
          crossorigin=""/>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
        }
        #map {
            height: 100vh;
            width: 100%;
        }
        .custom-div-icon {
            background: transparent;
            border: none;
        }
        .leaflet-popup-content-wrapper {
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        .leaflet-popup-content {
            margin: 12px 16px;
            line-height: 1.4;
        }
        .leaflet-popup-tip {
            background: white;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
            integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
            crossorigin=""></script>
    <script>
        // Initialize the map
        var map = L.map('map').setView([$centerLat, $centerLng], $zoom);

        // Add tile layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 19
        }).addTo(map);

        // Custom marker icon
        var customIcon = L.divIcon({
            className: 'custom-div-icon',
            html: \`<div style="
                background-color: #3B82F6; 
                width: 25px; 
                height: 25px; 
                border-radius: 50% 50% 50% 0; 
                border: 3px solid #ffffff; 
                transform: rotate(-45deg);
                box-shadow: 0 2px 4px rgba(0,0,0,0.3);
                position: relative;
            ">
                <div style="
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%) rotate(45deg);
                    width: 8px;
                    height: 8px;
                    background-color: white;
                    border-radius: 50%;
                "></div>
            </div>\`,
            iconSize: [25, 25],
            iconAnchor: [12, 24],
            popupAnchor: [1, -20]
        });

        // Add markers
        $markersJs

        // Disable zoom controls for better mobile experience
        map.touchZoom.disable();
        map.doubleClickZoom.disable();
        map.scrollWheelZoom.disable();
        map.boxZoom.disable();
        map.keyboard.disable();
        
        // Add zoom control in bottom right
        L.control.zoom({
            position: 'bottomright'
        }).addTo(map);

        // Fit map to show all markers if multiple markers exist
        if (${widget.markers.length} > 1) {
            var group = new L.featureGroup([
                ${widget.markers.map((marker) => 
                    'L.marker([${marker.lat}, ${marker.lng}])'
                ).join(', ')}
            ]);
            map.fitBounds(group.getBounds().pad(0.1));
        }

        // Handle window resize
        window.addEventListener('resize', function() {
            setTimeout(function() {
                map.invalidateSize();
            }, 100);
        });

        // Add custom controls
        var infoControl = L.control({position: 'topright'});
        infoControl.onAdd = function (map) {
            var div = L.DomUtil.create('div', 'info-control');
            div.innerHTML = \`
                <div style="
                    background: rgba(255,255,255,0.9);
                    padding: 8px 12px;
                    border-radius: 6px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                    font-size: 12px;
                    color: #333;
                    backdrop-filter: blur(10px);
                ">
                    <div style="font-weight: bold; color: #2563EB;">${widget.center.name}</div>
                    <div style="margin-top: 2px; color: #666;">📍 ${widget.center.address}</div>
                </div>
            \`;
            return div;
        };
        infoControl.addTo(map);
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat peta...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Error fallback
            if (!_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2563EB).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Alternative static map widget for cases where webview might not work
class StaticMapWidget extends StatelessWidget {
  final Place center;
  final List<Place> markers;

  const StaticMapWidget({
    Key? key,
    required this.center,
    this.markers = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB).withOpacity(0.1),
            Color(0xFF1D4ED8).withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/${center.lng},${center.lat},13,0/400x250@2x?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4NXVycTA2emYycXBndHRqcmZ3N3gifQ.rJcFIG214AriISLbB6B5aw',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.blue.withOpacity(0.1),
                  BlendMode.overlay,
                ),
              ),
            ),
          ),
          // Overlay with place info
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            center.address ?? 'Unknown address',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ketuk untuk membuka di Maps',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}