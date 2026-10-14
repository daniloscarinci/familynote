import 'messages.dart';

enum SaveStatus { saved, saving, pending }

String statusLabel(SaveStatus s) => switch (s) {
      SaveStatus.saved => 'Salvo',
      SaveStatus.saving => 'Salvando...',
      SaveStatus.pending => offlineMessage,
    };
