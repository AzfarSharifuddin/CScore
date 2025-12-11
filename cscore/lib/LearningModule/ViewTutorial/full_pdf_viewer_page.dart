import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:dio/dio.dart'; // Required for loading network PDFs

class FullPdfViewerPage extends StatefulWidget {
  final String fileName;
  // We now pass the raw data needed to load the document, not the pre-initialized controller.
  final String filePathOrUrl;
  final bool isAsset;

  const FullPdfViewerPage({
    super.key,
    required this.fileName,
    required this.filePathOrUrl,
    required this.isAsset,
  });

  @override
  State<FullPdfViewerPage> createState() => _FullPdfViewerPageState();
}

class _FullPdfViewerPageState extends State<FullPdfViewerPage> {
  // The controller is now initialized locally within this state
  late PdfControllerPinch _pdfController;
  bool _isControllerReady = false;

  @override
  void initState() {
    super.initState();
    _initializePdfController();
  }

  // Helper function to load a network PDF using Dio
  Future<PdfDocument> _loadNetworkPdf(String url) async {
    final response = await Dio().get(
      url, 
      options: Options(responseType: ResponseType.bytes),
    );
    return PdfDocument.openData(response.data);
  }

  // Determine the correct way to open the PDF document based on parameters
  void _initializePdfController() async {
    final path = widget.filePathOrUrl;
    late PdfDocument document;

    try {
      if (widget.isAsset) {
        document = await PdfDocument.openAsset(path);
      } else if (path.startsWith('http')) {
        document = await _loadNetworkPdf(path);
      } else {
        document = await PdfDocument.openFile(path);
      }
      
      // ✅ THE FINAL FIX: Wrap the fully loaded PdfDocument in a Future.value()
      // because PdfControllerPinch expects a Future<PdfDocument>, not a PdfDocument.
      _pdfController = PdfControllerPinch(
        document: Future.value(document),
      );
      
      // Set state to signal the UI that the controller is ready to use
      setState(() {
        _isControllerReady = true;
      });

    } catch (e) {
      // Handle potential loading errors (e.g., file not found, network issue)
      print('Error initializing PDF document: $e');
      // Optionally show a user-friendly error message here
      setState(() {
        _isControllerReady = false;
      });
    }
  }

  @override
  void dispose() {
    // Only dispose if it was initialized successfully
    if (_isControllerReady) {
      _pdfController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        // If not ready, show a loading indicator
        child: !_isControllerReady
            ? const CircularProgressIndicator(color: Colors.blue)
            : PdfViewPinch(
                controller: _pdfController,
              ),
      ),
    );
  }
}
