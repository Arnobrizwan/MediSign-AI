import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalGuidePage extends StatefulWidget {
  const HospitalGuidePage({Key? key}) : super(key: key);

  @override
  State<HospitalGuidePage> createState() => _HospitalGuidePageState();
}

class _HospitalGuidePageState extends State<HospitalGuidePage> {
  LatLng? _currentLatLng;
  late GoogleMapController _mapController;
  final Color _primaryColor = const Color(0xFFF45B69);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // You might show a dialog urging them to enable GPS
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
      );
    }
  }

  Future<void> _requestAmbulance() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Emergency Request'),
        content: const Text(
          'Are you sure you want to request emergency assistance?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Help is on the way. Your location has been shared. Stay calm.'
          ),
        ),
      );
      // TODO: send to your backend
    }
  }

  Future<void> _callEmergencyContact() async {
    final uri = Uri.parse('tel:+60123456789');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer'))
      );
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
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
            // Locator
            _currentLatLng == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('you'),
                        position: _currentLatLng!,
                        infoWindow: const InfoWindow(title: 'You are here'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                    },
                    zoomControlsEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),

            // Emergency
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.local_hospital, color: Colors.white),
                    label: const Text(
                      'REQUEST AMBULANCE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _requestAmbulance,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: _primaryColor),
                    ),
                    icon: const Icon(Icons.call, color: Color(0xFFF45B69)),
                    label: const Text(
                      'Call Emergency Contact',
                      style: TextStyle(fontSize: 16, color: Color(0xFFF45B69)),
                    ),
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
//flutter run -d chrome --web-port=50463 (fixed port for map running)