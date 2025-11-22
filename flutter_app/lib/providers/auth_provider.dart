import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/profile.dart';
import '../database/users_repository.dart';
import '../database/profiles_repository.dart';

class AuthProvider extends ChangeNotifier {
  static const _storageKey = 'currentUserId';
  final _secureStorage = const FlutterSecureStorage();
  final _usersRepo = UsersRepository();
  final _profilesRepo = ProfilesRepository();

  User? _user;
  Profile? _profile;
  bool _loading = true;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Seed demo account
      final demo = await _usersRepo.getUserByEmail('demo@example.com');
      if (demo == null) {
        final demoId = 'demo-${DateTime.now().millisecondsSinceEpoch}';
        final demoHash = _hashPassword('Passw0rd!');
        await _usersRepo.createUser(
          id: demoId,
          email: 'demo@example.com',
          name: 'Demo User',
          passwordHash: demoHash,
        );
      }

      // Rehydrate session
      final userId = await _secureStorage.read(key: _storageKey);
      if (userId != null) {
        _user = await _usersRepo.getUser(userId);
        if (_user != null) {
          _profile = await _profilesRepo.getProfile(userId);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<Map<String, dynamic>> signIn(String email, {String? password}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final u = await _usersRepo.getUserByEmail(email);
      if (u == null) {
        _error = 'No user found for that email';
        _loading = false;
        notifyListeners();
        return {'ok': false, 'error': _error};
      }

      if (u.passwordHash != null) {
        if (password == null) {
          _error = 'Password required';
          _loading = false;
          notifyListeners();
          return {'ok': false, 'error': _error};
        }
        
        final hash = _hashPassword(password);
        if (hash != u.passwordHash) {
          _error = 'Invalid credentials';
          _loading = false;
          notifyListeners();
          return {'ok': false, 'error': _error};
        }
      }

      await _secureStorage.write(key: _storageKey, value: u.id);
      _user = u;
      _profile = await _profilesRepo.getProfile(u.id);
      _loading = false;
      notifyListeners();
      return {'ok': true};
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return {'ok': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> signUp(
    String email, {
    String? name,
    String? password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = await _usersRepo.getUserByEmail(email);
      if (existing != null) {
        _error = 'User already exists';
        _loading = false;
        notifyListeners();
        return {'ok': false, 'error': _error};
      }

      final id = 'user-${DateTime.now().millisecondsSinceEpoch}';
      final passwordHash = password != null ? _hashPassword(password) : null;
      
      final u = await _usersRepo.createUser(
        id: id,
        email: email,
        name: name,
        passwordHash: passwordHash,
      );

      await _secureStorage.write(key: _storageKey, value: u.id);
      _user = u;
      _profile = await _profilesRepo.getProfile(u.id);
      _loading = false;
      notifyListeners();
      return {'ok': true};
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return {'ok': false, 'error': _error};
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();

    try {
      await _secureStorage.delete(key: _storageKey);
      _user = null;
      _profile = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Profile profile) async {
    if (_user == null) return;

    try {
      final newProfile = Profile(
        userId: _user!.id,
        sex: profile.sex ?? _profile?.sex,
        heightCm: profile.heightCm ?? _profile?.heightCm,
        weightKg: profile.weightKg ?? _profile?.weightKg,
        dob: profile.dob ?? _profile?.dob,
        age: profile.age ?? _profile?.age,
        activityLevel: profile.activityLevel ?? _profile?.activityLevel,
        equipment: profile.equipment.isNotEmpty ? profile.equipment : (_profile?.equipment ?? []),
        scheduleDays: profile.scheduleDays.isNotEmpty ? profile.scheduleDays : (_profile?.scheduleDays ?? []),
      );

      await _profilesRepo.upsertProfile(newProfile);
      _profile = newProfile;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
