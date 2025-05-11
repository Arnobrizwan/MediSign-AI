import 'dart:async';
import 'dart:convert';
import 'dart:html'  as html;   // for the dummy div on web
import 'dart:js'   as js;     // for JS interop on web

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HospitalGuidePage extends StatefulWidget {
  const HospitalGuidePage({Key? key}) : super(key: key);
  @override
  State<HospitalGuidePage> createState() => _HospitalGuidePageState();
}

class _HospitalGuidePageState extends State<HospitalGuidePage> {
  // Fallback REST key
  static const _placesApiKey = 'AIzaSyBsvzVLoa2VJg458tYlD16fyyH-W5mCfss';

  LatLng? _currentLatLng;
  late GoogleMapController _mapController;
  final _primaryColor = const Color(0xFFF45B69);

  List<_Hospital> _hospitals = [];
  bool _loadingHospitals = false;

  // Placeholder ambulances
  final _ambulances = [
    _Ambulance('A1', 1200, 3),
    _Ambulance('B2', 2600, 7),
    _Ambulance('C3', 4800, 12),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _currentLatLng = LatLng(pos.latitude, pos.longitude));

    if (kIsWeb) {
      await _fetchNearbyHospitalsWeb();
    } else {
      await _fetchNearbyHospitalsRest();
    }
  }

  /// Web: use a hidden DIV for PlacesService
  Future<void> _fetchNearbyHospitalsWeb() async {
    if (_currentLatLng == null) return;
    setState(() => _loadingHospitals = true);

    try {
      // Make an invisible DIV
      final container = html.DivElement();
      
      // Create the Google Maps Map object (required for PlacesService)
      final map = js.JsObject(
        js.context['google']['maps']['Map'],
        [container, js.JsObject.jsify({'center': js.JsObject.jsify({
          'lat': _currentLatLng!.latitude,
          'lng': _currentLatLng!.longitude,
        })})],
      );
      
      // Create the PlacesService with the map
      final service = js.JsObject(
        js.context['google']['maps']['places']['PlacesService'],
        [map],
      );

      // Build request
      final request = js.JsObject.jsify({
        'location': js.JsObject.jsify({
          'lat': _currentLatLng!.latitude,
          'lng': _currentLatLng!.longitude,
        }),
        'radius': 2000,
        'type': 'hospital',
      });

      // Fix: The callback needs to accept exactly 3 parameters
      final callback = js.allowInterop((results, status, pagination) {
        try {
          // Check status using object comparison
          final statusOk = js.context['google']['maps']['places']
                          ['PlacesServiceStatus']['OK'];
          
          if (status.toString() == statusOk.toString()) {
            final List<_Hospital> list = [];
            for (var r in results as List) {
              final place = js.JsObject.fromBrowserObject(r);
              final name = place['name'] as String? ?? 'Unnamed Hospital';
              final geometry = place['geometry'];
              if (geometry != null) {
                final loc = geometry['location'];
                final lat = (loc.callMethod('lat') as num).toDouble();
                final lng = (loc.callMethod('lng') as num).toDouble();
                final dist = Geolocator.distanceBetween(
                  _currentLatLng!.latitude,
                  _currentLatLng!.longitude,
                  lat, lng,
                );
                list.add(_Hospital(name, LatLng(lat, lng), dist));
              }
            }
            
            // Sort by distance
            list.sort((a, b) => a.distance.compareTo(b.distance));
            
            setState(() {
              _hospitals = list;
              _loadingHospitals = false;
            });
          } else {
            print('Places API error: $status');
            // Fallback to REST API if Places API fails
            _fetchNearbyHospitalsRest();
          }
        } catch (e) {
          print('Error parsing places results: $e');
          setState(() => _loadingHospitals = false);
          // Fallback to REST API if parsing fails
          _fetchNearbyHospitalsRest();
        }
      });

      // Call nearbySearch with the corrected callback
      service.callMethod('nearbySearch', [request, callback]);
      
    } catch (e) {
      print('Error initializing Places API: $e');
      setState(() => _loadingHospitals = false);
      // Fallback to REST API
      _fetchNearbyHospitalsRest();
    }
  }

  /// Mobile/Desktop: REST fallback
  Future<void> _fetchNearbyHospitalsRest() async {
    if (_currentLatLng == null) return;
    setState(() => _loadingHospitals = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentLatLng!.latitude},${_currentLatLng!.longitude}'
        '&radius=2000&type=hospital&key=$_placesApiKey',
      );
      final resp = await http.get(url);
      if (resp.statusCode != 200) {
        throw Exception('Failed to fetch hospitals: ${resp.statusCode}');
      }

      final body = json.decode(resp.body);
      final results = body['results'] as List<dynamic>;

      final list = <_Hospital>[];
      for (var item in results) {
        final name = item['name'] as String? ?? 'Unnamed Hospital';
        final loc = item['geometry']['location'];
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        final dist = Geolocator.distanceBetween(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
          lat, lng,
        );
        list.add(_Hospital(name, LatLng(lat, lng), dist));
      }
      
      // Sort by distance
      list.sort((a, b) => a.distance.compareTo(b.distance));
      
      setState(() {
        _hospitals = list;
        _loadingHospitals = false;
      });
    } catch (e) {
      print('Error fetching hospitals: $e');
      setState(() => _loadingHospitals = false);
    }
  }

  void _onMapCreated(GoogleMapController ctrl) {
    _mapController = ctrl;
    if (_currentLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
      );
    }
  }

  void _recenter() {
    if (_currentLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentLatLng!),
      );
    }
  }

  Future<void> _launchDirections(LatLng dest) async {
    if (_currentLatLng == null) return;
    
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentLatLng!.latitude},${_currentLatLng!.longitude}'
      '&destination=${dest.latitude},${dest.longitude}'
      '&travelmode=driving'
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _requestAmbulance() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Emergency Request'),
        content: const Text('Request emergency assistance?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambulance on the way!')),
      );
    }
  }

  Future<void> _callEmergencyContact() async {
    final uri = Uri.parse('tel:+60123456789');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: BackButton(color: Colors.black),
          title: const Text(
            'Hospital Services & Emergency',
            style: TextStyle(color: Color(0xFFF45B69), fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: _primaryColor,
            labelColor: _primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Locator', icon: Icon(Icons.map)),
              Tab(text: 'Emergency', icon: Icon(Icons.warning)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ─── Locator ─────────────────────────────────────
            if (_currentLatLng == null)
              const Center(child: CircularProgressIndicator())
            else
              Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng!, zoom: 15),
                    markers: {
                      Marker(
                        markerId: const MarkerId('you'),
                        position: _currentLatLng!,
                        infoWindow: const InfoWindow(title: 'You are here'),
                      ),
                      for (var h in _hospitals)
                        Marker(
                          markerId: MarkerId(h.name),
                          position: h.location,
                          infoWindow: InfoWindow(
                            title: '${h.name} — ${(h.distance/1000).toStringAsFixed(1)} km'
                          ),
                        ),
                    },
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),

                  Positioned(
                    top: 16, right: 16,
                    child: FloatingActionButton(
                      mini: true, backgroundColor: Colors.white,
                      onPressed: _recenter,
                      child: const Icon(Icons.my_location, color: Colors.black54),
                    ),
                  ),

                  DraggableScrollableSheet(
                    initialChildSize: 0.2,
                    minChildSize: 0.1,
                    maxChildSize: 0.4,
                    builder: (ctx, ctrl) {
                      if (_loadingHospitals) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                        ),
                        child: ListView.builder(
                          controller: ctrl,
                          itemCount: _hospitals.length + 1,
                          itemBuilder: (c,i) {
                            if (i==0) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('Nearby Hospitals',
                                  style: TextStyle(
                                    fontSize:16,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor
                                  )
                                ),
                              );
                            }
                            final h = _hospitals[i-1];
                            return ListTile(
                              leading: const Icon(Icons.local_hospital),
                              title: Text(h.name),
                              subtitle: Text('${(h.distance/1000).toStringAsFixed(1)} km'),
                              trailing: IconButton(
                                icon: const Icon(Icons.directions),
                                color: _primaryColor,
                                onPressed: () => _launchDirections(h.location),
                              ),
                              onTap: () => _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(h.location, 17),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),

            // ─── Emergency ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.local_hospital, color: Colors.white),
                    label: const Text('REQUEST AMBULANCE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    onPressed: _requestAmbulance,
                  ),
                  const SizedBox(height:16),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (_,__)=>const Divider(),
                      itemCount: _ambulances.length,
                      itemBuilder: (_,i){
                        final a = _ambulances[i];
                        return ListTile(
                          leading: const Icon(Icons.local_taxi, color: Colors.red),
                          title: Text(a.id),
                          subtitle: Text('${(a.distanceMeters/1000).toStringAsFixed(1)} km • ETA: ${a.etaMinutes} min'),
                          trailing: IconButton(
                            icon: const Icon(Icons.send, color: Colors.red),
                            onPressed: _requestAmbulance,
                          ),
                        );
                      }
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: _primaryColor),
                    ),
                    icon: const Icon(Icons.call, color: Color(0xFFF45B69)),
                    label: const Text('Call Emergency Contact',
                      style: TextStyle(fontSize:16,color:Color(0xFFF45B69))),
                    onPressed: _callEmergencyContact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hospital {
  final String name;
  final LatLng location;
  final double distance;
  _Hospital(this.name,this.location,this.distance);
}

class _Ambulance {
  final String id;
  final int distanceMeters;
  final int etaMinutes;
  _Ambulance(this.id,this.distanceMeters,this.etaMinutes);
}