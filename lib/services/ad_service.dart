// Bu dosya, google_mobile_ads paketinin kaldırılmasından sonra,
// geçici bir çözüm olarak sahte bir reklam servisi sağlar.

class AdService {
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;

  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  // Reklam servisini başlat
  Future<void> initialize() async {
    // Sahte reklam servisi - gelecekte gerçek bir reklam servisi ile değiştirilebilir
    print('Sahte reklam servisi başlatıldı');
    _isRewardedAdReady = true;
    _isInterstitialAdReady = true;
  }

  // Geçiş reklamını göster
  Future<bool> showInterstitialAd() async {
    print('Sahte geçiş reklamı gösteriliyor...');
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Ödüllü reklamı göster
  Future<bool> showRewardedAd({required Function onRewarded}) async {
    print('Sahte ödüllü reklam gösteriliyor...');
    await Future.delayed(const Duration(seconds: 1));
    onRewarded();
    return true;
  }

  void resetAdCounter() {
    // Sahte resetleme
  }

  void dispose() {
    // Sahte temizleme
  }
}
