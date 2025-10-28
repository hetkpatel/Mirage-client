// ignore_for_file: file_names, curly_braces_in_flow_control_structures, constant_identifier_names
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mirageclient/MiragePhotoData.dart';
import 'package:mirageclient/models/mirage_album.dart';
import 'package:mirageclient/models/mirage_memory.dart';
import 'package:mirageclient/models/mirage_utility.dart';
import 'package:mirageclient/sample_data.dart';

class MirageClient {
  static Future<Map<String, String>> _getHeaders() async => {
        HttpHeaders.authorizationHeader: await SessionManager().get("auth"),
      };

  static Future<List<dynamic>> _getJsonList(String path) async {
    final url = '${await SessionManager().get("server")}$path';
    final response =
        await http.get(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw HttpException(
      'Unexpected status ${response.statusCode} for $path',
      uri: Uri.parse(url),
    );
  }

  static Future<String> uploadFile(XFile file) async {
    try {
      String uploadUrl = '${await SessionManager().get("server")}/upload';
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers.addAll(await _getHeaders());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: file.name,
          contentType: MediaType.parse(file.mimeType ?? "application/*"),
        ),
      );

      var response = await request.send();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'File successfully uploaded';
      } else {
        if (kDebugMode) {
          print(response.statusCode);
          print(response.reasonPhrase);
        }
        return 'Failed to upload file: ${response.statusCode}';
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return '';
    }
  }

  static Future<String> startProcessing({required bool pullUploads}) async {
    String startProcessUrl =
        '${await SessionManager().get("server")}/start?pulluploads=$pullUploads';
    var response = await http.post(Uri.parse(startProcessUrl),
        headers: await _getHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return 'Process Started';
    } else {
      if (kDebugMode) {
        print(response.statusCode);
        print(response.reasonPhrase);
      }
      return 'Failed: ${response.statusCode}';
    }
  }

  static Future<List<MiragePhotoData>> getTrash() async {
    String trashUrl = '${await SessionManager().get("server")}/trash';
    var response =
        await http.get(Uri.parse(trashUrl), headers: await _getHeaders());

    if (response.statusCode == 200) {
      List<MiragePhotoData> result = [];
      for (var mirageFile in (jsonDecode(response.body) as List<dynamic>))
        result.add(MiragePhotoData.fromJson(mirageFile));
      return result;
    } else {
      if (kDebugMode) {
        print(response.statusCode);
        print(response.reasonPhrase);
      }
      return [];
    }
  }

  static Future<String> trash(String id) async {
    String trashUrl = '${await SessionManager().get("server")}/trash/$id';
    var response =
        await http.post(Uri.parse(trashUrl), headers: await _getHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return 'Complete';
    } else {
      if (kDebugMode) {
        print(response.statusCode);
        print(response.reasonPhrase);
      }
      return 'Failed: ${response.statusCode}';
    }
  }

  static Future<List<MiragePhotoData>> getPhotos() async {
    String listUrl = '${await SessionManager().get("server")}/list';
    var response =
        await http.get(Uri.parse(listUrl), headers: await _getHeaders());

    if (response.statusCode == 200) {
      List<MiragePhotoData> result = [];
      for (var mirageFile in (jsonDecode(response.body) as List<dynamic>))
        result.add(MiragePhotoData.fromJson(mirageFile));
      return result;
    } else {
      throw Exception('Failed to list files and folders');
    }
  }

  static Future<List<List<String>>> getSimilar() async {
    String similarUrl = '${await SessionManager().get("server")}/similar';
    var res =
        await http.get(Uri.parse(similarUrl), headers: await _getHeaders());

    if (res.statusCode == 200) {
      return jsonDecode(res.body)
          .map<List<String>>((innerList) => List<String>.from(innerList))
          .toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDiskUsage() async {
    String usageUrl = '${await SessionManager().get("server")}/usage';
    var res = await http.get(Uri.parse(usageUrl), headers: await _getHeaders());
    return jsonDecode(res.body);
  }

  static Future<List<MirageAlbum>> getAlbums() async {
    try {
      final list = await _getJsonList('/albums');
      return list
          .map((item) => MirageAlbum.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      if (kDebugMode) {
        print('Falling back to sample albums: $error');
      }
      return SampleData.albums();
    }
  }

  static Future<List<MirageUtilityItem>> getUtilities() async {
    try {
      final list = await _getJsonList('/utilities');
      return list
          .map((item) =>
              MirageUtilityItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      if (kDebugMode) {
        print('Falling back to sample utilities: $error');
      }
      return SampleData.utilities();
    }
  }

  static Future<List<MirageMemory>> getMemories() async {
    try {
      final url =
          '${await SessionManager().get("server")}/memories?limit=12&order=recent';
      final response =
          await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((item) =>
                MirageMemory.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw HttpException('Unexpected status ${response.statusCode}',
          uri: Uri.parse(url));
    } catch (error) {
      if (kDebugMode) {
        print('Falling back to sample memories: $error');
      }
      return SampleData.memories();
    }
  }
}
