import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; 
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


const String _baseUrl = 'http://127.0.0.1:8000';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

class PaqueteAsignado {
  final String idPaquete;
  final String direccion; 
  final double latDestino;
  final double lonDestino;

  PaqueteAsignado({
    required this.idPaquete,
    required this.direccion,
    required this.latDestino,
    required this.lonDestino,
  });
}

class InteractiveMapWidget extends StatelessWidget {
  final PaqueteAsignado paquete;
  final Position? currentPosition;

  const InteractiveMapWidget({
    super.key, 
    required this.paquete,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng destination = LatLng(paquete.latDestino, paquete.lonDestino);
    final Set<Marker> markers = {};

    // Marcador del destino
    markers.add(
      Marker(
        markerId: const MarkerId('destination_location'),
        position: destination,
        infoWindow: InfoWindow(
          title: 'Destino: ${paquete.idPaquete}',
          snippet: paquete.direccion,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Marcador de la ubicación actual si está disponible
    if (currentPosition != null) {
      final LatLng current = LatLng(
        currentPosition!.latitude, 
        currentPosition!.longitude
      );
      
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: current,
          infoWindow: const InfoWindow(
            title: 'Tu ubicación actual',
            snippet: 'Posición GPS obtenida',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    LatLng cameraTarget = destination;
    double zoom = 15.0;

    if (currentPosition != null) {
     
      cameraTarget = LatLng(
        (destination.latitude + currentPosition!.latitude) / 2,
        (destination.longitude + currentPosition!.longitude) / 2,
      );
      
  
      final distance = Geolocator.distanceBetween(
        destination.latitude,
        destination.longitude,
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
      
      if (distance > 1000) {
        zoom = 12.0;
      } else if (distance > 5000) {
        zoom = 10.0;
      }
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: cameraTarget,
            zoom: zoom, 
          ),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          onMapCreated: (GoogleMapController controller) {
         
          },
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usuarioController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingresa usuario y contraseña"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usuario': _usuarioController.text,
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final respBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final int idAgente = respBody['id_agente'];
        final String nombre = respBody['nombre'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bienvenido, $nombre!")),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FotoPage(
              idAgente: idAgente,
              nombreAgente: nombre,
              usuario: _usuarioController.text,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respBody['detail'] ?? "Error al iniciar sesión"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de conexión: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio de Sesión - Paquexpress"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_shipping,
              size: 80,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              "Paquexpress",
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: Colors.blueAccent
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sistema de Gestión de Entregas",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _usuarioController,
              decoration: const InputDecoration(
                labelText: "Usuario",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: "Ingresa tu usuario",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                hintText: "Ingresa tu contraseña",
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Iniciar Sesión"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class FotoPage extends StatefulWidget {
  final int idAgente;
  final String nombreAgente;
  final String usuario;
  
  const FotoPage({
    super.key, 
    required this.idAgente,
    required this.nombreAgente,
    required this.usuario,
  });

  @override
  _FotoPageState createState() => _FotoPageState();
}

class _FotoPageState extends State<FotoPage> {
  Uint8List? _imageBytes;
  XFile? _pickedFile;
  final picker = ImagePicker();
  
  List<PaqueteAsignado> _paquetes = [];
  PaqueteAsignado? _selectedPaquete;
  
  Position? _currentPosition;
  bool _isLoading = false;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchPaquetesAsignados(); 
  }
  
  Future<void> _fetchPaquetesAsignados() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/paquetes/asignados/${widget.idAgente}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _paquetes = data.map((item) {
            final dir = item['direccion'];
            final fullAddress = "${dir['calle_numero']}, ${dir['colonia']}, ${dir['ciudad']}";
            return PaqueteAsignado(
              idPaquete: item['id_paquete'],
              direccion: fullAddress,
              latDestino: dir['latitud_destino'],
              lonDestino: dir['longitud_destino'],
            );
          }).toList();
        });
        if (_paquetes.isNotEmpty && _selectedPaquete == null) {
            setState(() {
                _selectedPaquete = _paquetes.first;
            });
        }
      } else {
        throw Exception('Fallo al cargar paquetes: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar paquetes: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _pickedFile = pickedFile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto tomada correctamente ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se tomó ninguna foto ❌")),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _gettingLocation = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Servicio de ubicación desactivado 🚫")));
      setState(() {
        _gettingLocation = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permisos de ubicación denegados 🛑")));
        setState(() {
          _gettingLocation = false;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ubicación obtenida correctamente ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al obtener ubicación ❌")));
    } finally {
      setState(() {
        _gettingLocation = false;
      });
    }
  }

  Future registrarEntrega() async {
    if (_pickedFile == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falta tomar la foto ❗")),
      );
      return;
    }
    if (_selectedPaquete == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay paquete seleccionado ❗")),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falta obtener la ubicación GPS ❗")),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/entregas/'),
    );

    request.fields['id_paquete_fk'] = _selectedPaquete!.idPaquete;
    request.fields['id_agente_fk'] = widget.idAgente.toString(); 
    request.fields['latitud_gps'] = _currentPosition!.latitude.toString();
    request.fields['longitud_gps'] = _currentPosition!.longitude.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        _imageBytes!,
        filename: _pickedFile!.name,
      ),
    );

    try {
      var response = await request.send().timeout(const Duration(seconds: 30));
      var respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = null;
          _currentPosition = null;
          _selectedPaquete = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Entrega registrada con éxito! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar lista de paquetes
        _fetchPaquetesAsignados();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al registrar: ${response.statusCode} - $respStr ❌"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de conexión: $e ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar Sesión"),
          content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sesión cerrada correctamente"),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget mostrarImagenLocal() {
    if (_imageBytes == null) {
      return Column(
        children: [
          const Icon(Icons.photo_camera, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("Esperando foto de evidencia...", style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    return Column(
      children: [
        Image.memory(_imageBytes!, width: 300, height: 200, fit: BoxFit.cover),
        const SizedBox(height: 10),
        Text(
          "Foto lista para enviar",
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ubicación GPS:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_currentPosition != null) ...[
              Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Ubicación lista para entrega",
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.gps_off, color: Colors.grey, size: 16),
                  SizedBox(width: 8),
                  Text("Ubicación no obtenida", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            _gettingLocation
                ? const SizedBox(
                    height: 50,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text("Obteniendo ubicación...", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _getCurrentLocation, 
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text("Obtener Ubicación Actual"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Entrega - Paquexpress"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: "Cerrar Sesión",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                   
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blueAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.nombreAgente,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Usuario: ${widget.usuario} | ID: ${widget.idAgente}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                              onPressed: _fetchPaquetesAsignados,
                              tooltip: "Actualizar paquetes",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // 1. Selección de Paquete
                    const Text(
                      "1. Seleccionar Paquete:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _paquetes.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "No hay paquetes asignados",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : DropdownButton<PaqueteAsignado>(
                            value: _selectedPaquete,
                            isExpanded: true,
                            hint: const Text("Selecciona un paquete asignado"),
                            items: _paquetes.map((PaqueteAsignado paquete) {
                              return DropdownMenuItem<PaqueteAsignado>(
                                value: paquete,
                                child: Text(
                                  "${paquete.idPaquete} - ${paquete.direccion}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (PaqueteAsignado? newValue) {
                              setState(() {
                                _selectedPaquete = newValue;
                              });
                            },
                          ),
                    const SizedBox(height: 15),

                    if (_selectedPaquete != null)
                      InteractiveMapWidget(
                        paquete: _selectedPaquete!,
                        currentPosition: _currentPosition,
                    ),

                    const SizedBox(height: 20),

                    
                    const Text(
                      "2. Capturar Fotografía:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Center(child: mostrarImagenLocal()),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: getImage, 
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Tomar Foto de Evidencia"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                 
                    _buildLocationInfo(),
                    const SizedBox(height: 30),
                    
                 
                    ElevatedButton.icon(
                      onPressed: registrarEntrega, 
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Registrar Entrega"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    
                    
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Cerrar Sesión",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}