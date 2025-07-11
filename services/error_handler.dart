// lib/services/error_handler.dart - GLOBAL ERROR & LOADING MANAGER
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ErrorType {
  network,
  permission,
  storage,
  sensor,
  validation,
  authentication,
  unknown,
}

enum LoadingState {
  idle,
  loading,
  success,
  error,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, time: $timestamp)';
  }
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Error logging
  final List<AppError> _errorLog = [];
  final StreamController<AppError> _errorStream = StreamController<AppError>.broadcast();

  // Loading state management
  final Map<String, LoadingState> _loadingStates = {};
  final StreamController<Map<String, LoadingState>> _loadingStream =
      StreamController<Map<String, LoadingState>>.broadcast();

  // Streams
  Stream<AppError> get errorStream => _errorStream.stream;
  Stream<Map<String, LoadingState>> get loadingStream => _loadingStream.stream;

  /// Handle error with context
  Future<void> handleError(
    dynamic error, {
    ErrorType? type,
    String? message,
    String? context,
    StackTrace? stackTrace,
    bool showDialog = true,
    bool logError = true,
  }) async {
    final appError = _createAppError(error, type, message, context, stackTrace);

    if (logError) {
      _logError(appError);
    }

    _errorStream.add(appError);

    if (showDialog && _currentContext != null) {
      await _showErrorDialog(_currentContext!, appError);
    }
  }

  /// Create AppError from various error types
  AppError _createAppError(
    dynamic error,
    ErrorType? type,
    String? message,
    String? context,
    StackTrace? stackTrace,
  ) {
    ErrorType errorType = type ?? _determineErrorType(error);
    String errorMessage = message ?? _extractErrorMessage(error);

    if (context != null) {
      errorMessage = '$context: $errorMessage';
    }

    return AppError(
      type: errorType,
      message: errorMessage,
      details: error.toString(),
      stackTrace: stackTrace,
    );
  }

  /// Determine error type from exception
  ErrorType _determineErrorType(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return ErrorType.network;
    } else if (error is PlatformException) {
      if (error.code.contains('PERMISSION')) {
        return ErrorType.permission;
      } else if (error.code.contains('SENSOR')) {
        return ErrorType.sensor;
      }
      return ErrorType.unknown;
    } else if (error is FileSystemException) {
      return ErrorType.storage;
    } else if (error is FormatException || error is ArgumentError) {
      return ErrorType.validation;
    }
    return ErrorType.unknown;
  }

  /// Extract user-friendly message from error
  String _extractErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'İnternet bağlantısı sorunu';
    } else if (error is TimeoutException) {
      return 'İşlem zaman aşımına uğradı';
    } else if (error is PlatformException) {
      return _getPlatformErrorMessage(error);
    } else if (error is FileSystemException) {
      return 'Dosya işlemi başarısız';
    } else if (error is FormatException) {
      return 'Geçersiz veri formatı';
    } else if (error.toString().contains('permission')) {
      return 'İzin hatası';
    }
    return 'Beklenmeyen bir hata oluştu';
  }

  /// Get platform-specific error messages
  String _getPlatformErrorMessage(PlatformException error) {
    switch (error.code) {
      case 'PERMISSION_DENIED':
        return 'İzin reddedildi';
      case 'SENSOR_NOT_AVAILABLE':
        return 'Sensör mevcut değil';
      case 'NETWORK_ERROR':
        return 'Ağ hatası';
    }
    return error.message ?? 'Platform hatası';
  }

  /// Log error
  void _logError(AppError error) {
    _errorLog.add(error);

    // Keep only last 100 errors
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }

    // Print to console in debug mode
    debugPrint('🚨 ${error.type.name.toUpperCase()}: ${error.message}');
    if (error.details != null) {
      debugPrint('   Details: ${error.details}');
    }
  }

  /// Current context for dialogs
  BuildContext? _currentContext;

  void setContext(BuildContext context) {
    _currentContext = context;
  }

  /// Show error dialog
  Future<void> _showErrorDialog(BuildContext context, AppError error) async {
    final errorInfo = _getErrorDisplayInfo(error.type);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(errorInfo.icon, color: errorInfo.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorInfo.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (errorInfo.solution.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: errorInfo.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorInfo.solution,
                        style: TextStyle(
                          fontSize: 14,
                          color: errorInfo.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (errorInfo.hasRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Trigger retry logic here
              },
              child: const Text('Tekrar Dene'),
            ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Get error display information
  ErrorDisplayInfo _getErrorDisplayInfo(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return ErrorDisplayInfo(
          title: 'Bağlantı Hatası',
          icon: Icons.wifi_off,
          color: Colors.orange,
          solution: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
          hasRetry: true,
        );
      case ErrorType.permission:
        return ErrorDisplayInfo(
          title: 'İzin Hatası',
          icon: Icons.block,
          color: Colors.red,
          solution: 'Ayarlardan gerekli izinleri verin.',
          hasRetry: false,
        );
      case ErrorType.storage:
        return ErrorDisplayInfo(
          title: 'Depolama Hatası',
          icon: Icons.storage,
          color: Colors.purple,
          solution: 'Cihazınızda yeterli alan olduğundan emin olun.',
          hasRetry: true,
        );
      case ErrorType.sensor:
        return ErrorDisplayInfo(
          title: 'Sensör Hatası',
          icon: Icons.sensors_off,
          color: Colors.blue,
          solution: 'Cihazınızın sensörlerini kontrol edin.',
          hasRetry: true,
        );
      case ErrorType.validation:
        return ErrorDisplayInfo(
          title: 'Veri Hatası',
          icon: Icons.error_outline,
          color: Colors.amber,
          solution: 'Girdiğiniz bilgileri kontrol edin.',
          hasRetry: false,
        );
      case ErrorType.authentication:
        return ErrorDisplayInfo(
          title: 'Kimlik Doğrulama Hatası',
          icon: Icons.person_off,
          color: Colors.red,
          solution: 'Tekrar giriş yapmayı deneyin.',
          hasRetry: true,
        );
      case ErrorType.unknown:
        return ErrorDisplayInfo(
          title: 'Bilinmeyen Hata',
          icon: Icons.help_outline,
          color: Colors.grey,
          solution: 'Uygulamayı yeniden başlatmayı deneyin.',
          hasRetry: true,
        );
    }
  }

  // LOADING STATE MANAGEMENT

  /// Set loading state
  void setLoading(String key, {bool isLoading = true}) {
    _loadingStates[key] = isLoading ? LoadingState.loading : LoadingState.idle;
    _loadingStream.add(Map.from(_loadingStates));
  }

  /// Set success state
  void setSuccess(String key) {
    _loadingStates[key] = LoadingState.success;
    _loadingStream.add(Map.from(_loadingStates));

    // Auto-clear after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (_loadingStates[key] == LoadingState.success) {
        _loadingStates[key] = LoadingState.idle;
        _loadingStream.add(Map.from(_loadingStates));
      }
    });
  }

  /// Set error state
  void setError(String key) {
    _loadingStates[key] = LoadingState.error;
    _loadingStream.add(Map.from(_loadingStates));
  }

  /// Get loading state
  LoadingState getLoadingState(String key) {
    return _loadingStates[key] ?? LoadingState.idle;
  }

  /// Check if loading
  bool isLoading(String key) {
    return _loadingStates[key] == LoadingState.loading;
  }

  /// Execute with loading state
  Future<T?> executeWithLoading<T>(
    String key,
    Future<T> Function() operation, {
    String? errorContext,
    bool showErrorDialog = true,
  }) async {
    try {
      setLoading(key);
      final result = await operation();
      setSuccess(key);
      return result;
    } catch (error, stackTrace) {
      setError(key);
      await handleError(
        error,
        context: errorContext,
        stackTrace: stackTrace,
        showDialog: showErrorDialog,
      );
      return null;
    }
  }

  // ERROR LOG MANAGEMENT

  /// Get error log
  List<AppError> getErrorLog() => List.unmodifiable(_errorLog);

  /// Clear error log
  void clearErrorLog() {
    _errorLog.clear();
  }

  /// Get error statistics
  Map<ErrorType, int> getErrorStatistics() {
    final stats = <ErrorType, int>{};
    for (final error in _errorLog) {
      stats[error.type] = (stats[error.type] ?? 0) + 1;
    }
    return stats;
  }

  /// Export error log (for debugging)
  String exportErrorLog() {
    final buffer = StringBuffer();
    buffer.writeln('FormdaKal Error Log - ${DateTime.now()}');
    buffer.writeln('=' * 50);

    for (final error in _errorLog) {
      buffer.writeln('${error.timestamp}: ${error.type.name.toUpperCase()}');
      buffer.writeln('Message: ${error.message}');
      if (error.details != null) {
        buffer.writeln('Details: ${error.details}');
      }
      buffer.writeln('-' * 30);
    }

    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    _errorStream.close();
    _loadingStream.close();
  }
}

/// Error display information
class ErrorDisplayInfo {
  final String title;
  final IconData icon;
  final Color color;
  final String solution;
  final bool hasRetry;

  ErrorDisplayInfo({
    required this.title,
    required this.icon,
    required this.color,
    required this.solution,
    required this.hasRetry,
  });
}

/// Loading Widget for easy usage
class LoadingWidget extends StatelessWidget {
  final String loadingKey;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final VoidCallback? onRetry;

  const LoadingWidget({
    super.key,
    required this.loadingKey,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, LoadingState>>(
      stream: ErrorHandler().loadingStream,
      builder: (context, snapshot) {
        final loadingState = ErrorHandler().getLoadingState(loadingKey);

        // DÜZELTME: 'default' ifadesi gereksiz olduğu için kaldırıldı.
        // Her 'case' durumu zaten ele alınıyor.
        switch (loadingState) {
          case LoadingState.loading:
            return loadingWidget ?? _buildDefaultLoading();
          case LoadingState.error:
            return errorWidget ?? _buildDefaultError(context);
          case LoadingState.success:
            return _buildSuccessIndicator();
          case LoadingState.idle:
            return child;
        }
      },
    );
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Yükleniyor...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lütfen tekrar deneyin',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessIndicator() {
    return Stack(
      children: [
        child,
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Başarılı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Smart Loading Button
class LoadingButton extends StatelessWidget {
  final String loadingKey;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.loadingKey,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, LoadingState>>(
      stream: ErrorHandler().loadingStream,
      builder: (context, snapshot) {
        final isLoading = ErrorHandler().isLoading(loadingKey);

        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Yükleniyor...'),
                  ],
                )
              : child,
        );
      },
    );
  }
}

/// Network-aware widget (Simplified without connectivity_plus)
class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Simplified version without connectivity_plus dependency
    // In a real app, you would add connectivity_plus to pubspec.yaml
    return child;
  }
}

/// Safe Area wrapper with error handling
class SafeWrapper extends StatelessWidget {
  final Widget child;
  final String? errorContext;

  const SafeWrapper({
    super.key,
    required this.child,
    this.errorContext,
  });

  @override
  Widget build(BuildContext context) {
    ErrorHandler().setContext(context);

    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          ErrorHandler().handleError(
            error,
            context: errorContext,
            stackTrace: stackTrace,
            showDialog: false,
          );

          return _buildErrorFallback(context);
        }
      },
    );
  }

  Widget _buildErrorFallback(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bir şeyler ters gitti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              errorContext ?? 'Beklenmeyen bir hata oluştu',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}

// Note: To use NetworkAwareWidget with full functionality,
// add 'connectivity_plus: ^5.0.2' to pubspec.yaml dependencies
