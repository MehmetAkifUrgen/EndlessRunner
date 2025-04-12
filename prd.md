# Oyun Projesi - PRD

## Proje Özeti

"Endless Runner" oyunumuz, kullanıcılara eğlenceli ve bağımlılık yapıcı bir oyun deneyimi sunmak amacıyla geliştirilmiştir. Oyun, Flutter ve Flame oyun motoru kullanılarak oluşturulmuştur. Oyuncular, engelleri atlayarak, güç-yükseltmeleri toplayarak ve puanlarını en üst seviyeye çıkararak ilerlemektedir.

## Oyun Özellikleri

### Ana Mekanikler
- **Basılı Tutma Zıplama Sistemi**: Oyuncular, ekrana basma süresine göre farklı yüksekliklerde zıplayabilir
- **Çift Zıplama**: Havadayken ikinci bir zıplama yapabilme yeteneği
- **Kayma ve Dash Hareketleri**: Engellerin altından kaymak ve hızla ileri atılmak için özel hareketler
- **Otomatik İlerleyen Oyun Dünyası**: Engeller ve toplanabilir öğeler sürekli olarak oyuncuya doğru gelir
- **Zorluk Seviyesi Artışı**: Oyun süresi ilerledikçe hız otomatik olarak artar
- **Can Sistemi**: Oyuncular 3 cana sahiptir, engele çarpınca 1 can kaybedilir

### Gelişmiş Mekanikler
- **Combo Sistemi**: Toplanabilirleri art arda toplamak combo sayacını artırır
- **Puan Çarpanı**: Combo sayısı arttıkça kazanılan puanlar da artar
- **Renkli Combo Göstergesi**: Combo sayısına göre renk değişimi yapan görsel geri bildirim
- **Oyuncu Animasyonları**: Hareket tipine göre değişen karakter görünümü ve animasyonları

### Güç-Yükseltmeler
- **Mıknatıs**: Civardaki paraları oyuncuya çeker (8 saniye)
- **Kalkan**: Geçici dokunulmazlık sağlar (5 saniye)
- **Yavaş Çekim**: Oyun hızını yavaşlatır (5 saniye)
- **Skor Artırıcı**: Ekstra puan ve combo sağlar
- **Ekstra Can**: Oyuncuya bir can ekler (maksimum 3)

### Toplanabilir Öğeler
- **Altın**: Standart puan öğesi (%75 şansla)
- **Ekstra Can**: Oyuncuya can ekler (%5 şansla)
- **Kalkan**: Geçici koruma sağlar (%5 şansla)
- **Mıknatıs**: Paraları çeker (%5 şansla)
- **Yavaş Çekim**: Oyunu yavaşlatır (%3 şansla)
- **Skor Artırıcı**: Ekstra puan verir (%7 şansla)

### Görsel Özellikler
- **Dinamik Karakter Animasyonları**: Koşma, zıplama, kayma ve dash animasyonları
- **Aktif Güç Göstergeleri**: Aktif güçler ve kalan süreleri ekranda gösterilir
- **Özel Tasarlanmış Güç-Yükseltme Sembolleri**: Her güç için özel görsel tasarım
- **Parlama ve Efekt Animasyonları**: Toplanabilir öğeler için parlama efektleri
- **Çok Katmanlı Arka Plan**: Dağlar, bulutlar ve zemin elementleri
- **İnsan Benzeri Karakter Tasarımı**: Detaylı insan formu ve yüz ifadeleri

## Kullanıcı Arayüzü
- **Puan Göstergesi**: Oyuncunun mevcut puanını gösterir
- **Can Göstergesi**: Kalan canları görsel olarak gösterir
- **Combo Sayacı**: Mevcut combo sayısını renkli şekilde gösterir
- **Aktif Güç Göstergeleri**: Hangi güçlerin aktif olduğunu ve kalan sürelerini gösterir
- **Oyun Duraklatma**: Oyunu duraklatmak için buton
- **Oyun Bitti Ekranı**: Oyun bittiğinde puanı ve yeniden başlatma seçeneğini gösterir
- **Ana Menü**: Oyun bitiminde ana menüye dönme seçeneği
- **Zıplama Güç Göstergesi**: Zıplama kuvvetini görsel olarak gösteren çubuk
- **Tutorial Bilgilendirme**: Oyun başında kontrol açıklamaları

## Teknik Özellikler
- **Flame Oyun Motoru**: 2D oyun geliştirme için Flutter'a entegre framework
- **Çarpışma Sistemi**: Hassas çarpışma algılama ve tepkileri
- **Performans Optimizasyonu**: Akıcı oyun deneyimi için optimize edilmiş kod
- **Duyarlı Kullanıcı Girişi**: Basılı tutma, dokunma ve tepki verme için gelişmiş giriş sistemi
- **Yüksek Skor Saklama**: Oyuncunun en yüksek skorunu kaydetme ve gösterme
- **Responsive Tasarım**: Farklı ekran boyutlarına uyum sağlayan arayüz
- **Dokunuş Hareketi Tanıma**: Kaydırma ve dokunma hareketleri için gelişmiş tanıma

## Performans Optimizasyonları
- **Görsel Öğe Sınırlaması**: Ekrandaki grafik öğelerinin sayısı optimize edildi
- **Render Optimizasyonu**: Ekran dışındaki nesneler render edilmiyor
- **Basitleştirilmiş Şekiller**: Karmaşık eğriler yerine basit çizimler kullanılıyor
- **Önbelleğe Alınmış Çizimler**: Sık kullanılan şekiller önceden hazırlanıyor
- **Obje Havuzu**: Nesnelerin yeniden kullanımı için optimize edilmiş sistem
- **Detay Seviyesi Kontrolü**: Uzaktaki veya önemsiz nesnelerde daha az detay
- **Çarpışma Kutusu Optimizasyonu**: Basitleştirilmiş çarpışma algılama

## Gelecek Geliştirmeler
- **Şerit Değiştirme Sistemi**: Sağa/sola kaydırarak şerit değiştirebilme
- **Karakter Özelleştirme**: Farklı karakterler ve görünümler
- **Seviye Sistemi**: Artan zorluklarla farklı seviyeler
- **Özel Efektler ve Parçacık Sistemleri**: Daha zengin görsel deneyim
- **Ses Efektleri ve Müzik**: Atmosferik oyun deneyimi
- **Yüksek Skor Tablosu**: Çevrimiçi yüksek skor rekabeti
- **Başarılar ve Ödüller**: Oyuncuya motivasyon sağlayacak hedefler
- **Çoklu Tema**: Farklı oyun temaları ve görsel stiller
- **Oyuniçi Ekonomi**: Toplanan altınların kullanılabileceği bir sistemi
- **Oyuncu İlerlemesi**: Kalıcı yükseltmeler ve beceri ağacı

## Test Sonuçları
- **Performans**: Oyun tüm desteklenen platformlarda 60 FPS'de çalışıyor
- **Kullanıcı Geri Bildirimi**: İlk testlerde basılı tutma zıplama mekanizması ve güç-yükseltmeler beğenildi
- **Dengeli Zorluk Seviyesi**: Oyun zamanla zorlaşırken adil bir öğrenme eğrisi sunuyor
- **Çapraz Platform Uyumluluk**: Mobil, web ve masaüstü platformlarda sorunsuz çalışma
- **Tarayıcı Uyumluluğu**: Chrome, Firefox ve Safari'de test edildi
