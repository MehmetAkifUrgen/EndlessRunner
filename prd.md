# Oyun Projesi - PRD (Güncelleme: Mayıs 2024)

## Proje Özeti

"Endless Runner" oyunumuz, kullanıcılara eğlenceli ve bağımlılık yapıcı bir oyun deneyimi sunmak amacıyla geliştirilmiştir. Oyun, Flutter ve Flame oyun motoru kullanılarak oluşturulmuştur. Oyuncular, silahlı bir insan karakteri ile rastgele ortaya çıkan düşmanlarla mücadele ederek, engelleri atlayarak, ateş ederek, güç-yükseltmeleri toplayarak ve puanlarını en üst seviyeye çıkararak ilerlemektedir.

## Teknik Özellikler
- **Flutter Versiyonu**: 3.0.0+
- **Flame Versiyonu**: 1.28.0
- **Provider Versiyonu**: 6.0.5
- **Dart SDK Versiyonu**: '>=3.0.0 <4.0.0'
- **flutter_cube**: 0.1.1
- **shared_preferences**: 2.2.1
- **audioplayers**: 6.4.0
- **just_audio**: 0.9.36

## Oyun Özellikleri

### Ana Mekanikler
- **Basılı Tutma Zıplama Sistemi**: Oyuncular, ekrana basma süresine göre farklı yüksekliklerde zıplayabilir
- **Çift Zıplama**: Havadayken ikinci bir zıplama yapabilme yeteneği
- **Kayma ve Dash Hareketleri**: Engellerin altından kaymak ve hızla ileri atılmak için özel hareketler
- **Otomatik İlerleyen Oyun Dünyası**: Engeller, düşmanlar ve toplanabilir öğeler sürekli olarak oyuncuya doğru gelir
- **Zorluk Seviyesi Artışı**: Oyun süresi ilerledikçe hız otomatik olarak artar
- **Can Sistemi**: Oyuncular 3 cana sahiptir, engele veya düşmana çarpınca 1 can kaybedilir
- **Silah Sistemi**: Oyuncu silahla ateş ederek düşmanları öldürebilir
- **Mermi Sistemi**: Sınırlı mermi sayısı ve oyun sırasında mermi toplayabilme
- **Katmanlı Oyun Dünyası**: Farklı yüksekliklerde platformlar ve zıplayarak geçilebilen alanlar
- **Seviye Sistemi**: Oyuncular XP toplayarak seviye atlar ve daha zorlu aşamalara ulaşır

### Gelişmiş Mekanikler
- **Combo Sistemi**: Toplanabilirleri art arda toplamak combo sayacını artırır
- **Puan Çarpanı**: Combo sayısı arttıkça kazanılan puanlar da artar
- **Renkli Combo Göstergesi**: Combo sayısına göre renk değişimi yapan görsel geri bildirim
- **Oyuncu Animasyonları**: Hareket tipine göre değişen karakter görünümü ve animasyonları
- **Düşman Animasyonları**: Farklı düşman tiplerinde çeşitli animasyonlar
- **Ateş Etme Mekanikleri**: Farklı silahlar ve ateş etme modları
- **Düşman Yapay Zekası**: Düşmanların oyuncuya yaklaşma ve saldırma davranışları

### Karakter Sistemi
- **İnsan Karakteri**: Oyuncu, elinde silah taşıyan bir insan karakterini kontrol eder
- **Farklı Karakter Seçenekleri**: Beş farklı karakter bulunmaktadır:
  - **Tavşan**: Başlangıç karakteri, dengeli özellikler (Ücretsiz)
  - **Çita**: Yüksek hız, orta zıplama yeteneği (1000 altın)
  - **Kurbağa**: Yüksek zıplama gücü, orta hız (1500 altın)
  - **Tilki**: Güçlü dash yeteneği ve para çarpanı (2000 altın)
  - **Kartal**: VIP karakter, tüm özelliklerde artış ve 1.5x para çarpanı (5000 altın)
- **Karakter Özellikleri**: Her karakterin kendine özgü özellikleri vardır:
  - **Zıplama Gücü**: Karakterin zıplama yüksekliğini etkiler
  - **Hız**: Karakterin hareket hızını belirler
  - **Dash Gücü**: Dash hareketi yapılırken alınan mesafeyi etkiler
  - **Para Çarpanı**: Toplanan altınların değerini artırır
- **Karakter Kilit Sistemi**: Karakterler oyun içi altın ile açılabilir

### Silah Sistemi
- **Farklı Silah Türleri**: Dört temel silah tipi bulunmaktadır:
  - **Tabanca**: Standart silah, orta hasar, hızlı ateş etme (12 mermi kapasitesi)
  - **Pompalı**: Yüksek hasar, yavaş ateş etme, patlama etkisi (6 mermi kapasitesi)
  - **Tüfek**: Orta hasar, çok hızlı ateş etme, delici mermiler (30 mermi kapasitesi)
  - **Lazer Silahı**: Yüksek hasar, hızlı ateş etme, delici etkili (20 mermi kapasitesi)
- **Silah Mermileri**: Her silahın kendine özgü mermi tipi ve görsel efekti bulunur
- **Mermi Özellikleri**: Mermiler farklı özelliklere sahiptir:
  - **Hasar**: Düşmanlara verilen hasar miktarı
  - **Hız**: Merminin hareket hızı
  - **Boyut**: Merminin görsel boyutu
  - **Renk**: Her silah tipine özgü mermi rengi
  - **Delici Özellik**: Bazı mermiler düşmanları delip geçebilir
  - **Patlayıcı Özellik**: Bazı mermiler çarptığında patlama etkisi yaratır
- **Mermi Sistemi**: Oyuncu sınırlı mermi sayısına sahiptir ve oyun sırasında mermi kutuları toplayabilir
- **Güçlendirilmiş Atış**: Özel güç-yükseltmesi ile geçici olarak daha güçlü mermiler elde edilebilir

### Düşman Sistemi
- **Farklı Düşman Tipleri**: Beş temel düşman tipi bulunmaktadır:
  - **Temel Düşman**: Basit ve zayıf, 1 can, saldırı yok (10 puan)
  - **Zombi**: Orta güçte, 2 can, yakın mesafe saldırısı (15 puan)
  - **Robot**: Dayanıklı, 3 can, yakın veya uzak mesafe saldırısı (20 puan)
  - **Canavar**: Güçlü, 3 can, bazıları uçabilir veya zıplayabilir, farklı saldırı tipleri (25 puan)
  - **Boss Düşman**: Çok güçlü, 10 can, sihirli saldırı, yüksek hasar (100 puan)
- **Düşman Davranışları**:
  - **Saldırı Tipleri**: Yakın dövüş, uzak mesafe, sihirli saldırılar
  - **Hareket Yetenekleri**: Yürüme, koşma, zıplama, uçma
  - **Agresiflik Seviyesi**: Düşmanın oyuncuyu tespit etme mesafesi ve saldırganlığı
- **Seviye Tabanlı Düşman Güçlendirmesi**: Üst seviyelerde düşmanlar daha güçlü olur
- **Boss Düşman Şansı**: Oyun seviyesi yükseldikçe Boss düşman gelme olasılığı artar

### Mermi Sistemi
- **Sınırlı Mermi**: Oyuncu varsayılan olarak maksimum kapasitenin yarısıyla başlar (25 mermi)
- **Mermi Toplayıcılar**: Düşmanları öldürünce veya mermi kutuları toplayarak mermi elde edilebilir
- **Farklı Mermi Tipleri**: Her silah kendine özgü mermi tipi, rengi ve efekti kullanır
- **Mermi Göstergesi**: Ekranda kalan mermi sayısı görsel olarak gösterilir
- **Mermi Kutusu Oluşturma**: Düşmanların, özelliklerine göre farklı şanslarla mermi kutusu düşürme olasılığı vardır:
  - Temel Düşman: %10
  - Zombi: %20
  - Robot: %50
  - Canavar: %35
  - Boss: %100 (Her zaman mermi kutusu düşürür)

### Güç-Yükseltmeler
- **Mıknatıs**: Civardaki paraları oyuncuya çeker (8 saniye)
- **Kalkan**: Geçici dokunulmazlık sağlar (5 saniye)
- **Yavaş Çekim**: Oyun hızını yavaşlatır (5 saniye)
- **Skor Artırıcı**: Ekstra puan ve combo sağlar
- **Ekstra Can**: Oyuncuya bir can ekler (maksimum 3)
- **Mermi Paketi**: Ekstra mermi sağlar
- **Güçlü Ateş**: Geçici olarak daha güçlü mermiler (5 saniye)
- **Güç-Yükseltme Görsel Göstergeleri**: Aktif güçler ekranda ikon ve kalan süreleriyle gösterilir
- **Görsel Efektler**: Her güç-yükseltmenin kendine özgü aktivasyon ve devam eden efektleri vardır

### Toplanabilir Öğeler
- **Altın**: Standart puan öğesi (%70 şansla)
- **Ekstra Can**: Oyuncuya can ekler (%5 şansla)
- **Kalkan**: Geçici koruma sağlar (%5 şansla)
- **Mıknatıs**: Paraları çeker (%5 şansla)
- **Mermi Paketi**: Ekstra mermi sağlar (%10 şansla)
- **Güçlü Ateş**: Geçici güçlü mermiler (%3 şansla)
- **Yavaş Çekim**: Oyunu yavaşlatır (%2 şansla)

### Katmanlı Oyun Dünyası
- **Çoklu Platform Sistemi**: Farklı yüksekliklerde platformlar
- **Platform Geçişleri**: Zıplayarak üst platformlara çıkabilme
- **Platform Özellikleri**: Kırılgan, hareketli, geçici gibi çeşitli platform tipleri
- **Paralaks Arka Plan**: Çok katmanlı derinlik hissi veren arka plan
- **Üç Boyutlu Görünüm**: 2D elemanlarla oluşturulmuş 3D hissi veren katmanlı dünya

### Görsel Özellikler
- **Dinamik Karakter Animasyonları**: Koşma, zıplama, kayma, ateş etme ve dash animasyonları
- **İnsan Benzeri Karakter Tasarımı**: Detaylı insan formu ve yüz ifadeleri
- **Silah Animasyonları**: Ateş etme, şarjör değiştirme, silah değiştirme animasyonları
- **Düşman Animasyonları**: Hareket, saldırı, ölüm animasyonları
- **Aktif Güç Göstergeleri**: Aktif güçler ve kalan süreleri ekranda gösterilir
- **Özel Tasarlanmış Güç-Yükseltme Sembolleri**: Her güç için özel görsel tasarım
- **Patlama ve Vurulma Efektleri**: Düşmanları vurma ve patlama görsel efektleri
- **Parlama ve Efekt Animasyonları**: Toplanabilir öğeler için parlama efektleri
- **Çok Katmanlı Arka Plan**: Dağlar, bulutlar ve zemin elementleri
- **Özel Şık Engeller**: Farklı tipteki engeller için gradient ve parıltı efektleri içeren gelişmiş tasarımlar
- **Doğal Renk Şeması**: Dağlar ve arkaplan için gerçekçi renk tonları
- **Seviye Atlama Animasyonu**: Seviye atlandığında oyun içi ekranda özel animasyonlu bildirim
- **Parçacık Efektleri**: Zıplama, koşma, çarpışma ve ateş etme sırasında parçacık efektleri

### Tema Sistemi
- **Özelleştirilebilir Temalar**: 5 farklı oyun teması bulunmaktadır:
  - **Classic** (Varsayılan ve ücretsiz): Mavi gökyüzü, yeşil zemin, kırmızı engeller
  - **Night Mode** (1000 altın): Koyu mavi/siyah gökyüzü, mor zemin, efektler
  - **Jungle** (2000 altın): Yeşil tonları, kahverengi engeller, orman efektleri
  - **Lava World** (3000 altın): Kırmızı/turuncu gökyüzü, turuncu zemin, ateş efektleri
  - **Winter Scene** (2500 altın): Beyaz/mavi gökyüzü, beyaz zemin, buz efektleri
- **Tema Özellikleri**: Her tema şu özelliklerle tanımlanır:
  - **Ana Renk**: Temanın baskın rengi
  - **İkincil Renk**: Vurgular ve detaylar için kullanılan renk
  - **Arkaplan Gradyanı**: Gökyüzü için 3 renkli gradyan
  - **Engel Rengi**: Engeller için temel renk
  - **Zemin Rengi**: Oyun zemini için renk
  - **Oyuncu Rengi**: Karakter vurguları için renk
- **Tema Mağazası**: Oyunda kazanılan altınlarla satın alınabilen temalar
- **Aktif Tema Gösterimi**: Mevcut seçili temayı gösteren arayüz
- **Tema Önizleme**: Satın almadan önce temaları önizleme imkanı

### Seviye Sistemi
- **Tecrübe Puanı (XP)**: Oyun içi puanların bir kısmı XP olarak kaydedilir
- **Seviye İlerleme Çubuğu**: Mevcut XP durumunu görsel olarak gösteren çubuk
- **Seviye Ödülleri**: Her seviyede artan puan çarpanı ve özel içerikler
- **Seviye Tabanlı Zorluk**: Üst seviyelerde daha hızlı ve zor oyun deneyimi
- **Seviye Seçim Ekranı**: Açılan seviyeleri görüntüleme ve seçme imkanı
- **Seviye Atlama Bildirimi**: Yeni seviyeye ulaşıldığında özel bildirim

## Kullanıcı Arayüzü
- **Puan Göstergesi**: Oyuncunun mevcut puanını gösterir
- **Can Göstergesi**: Kalan canları görsel olarak gösterir
- **Mermi Göstergesi**: Kalan mermi sayısını gösterir
- **Combo Sayacı**: Mevcut combo sayısını renkli şekilde gösterir
- **Aktif Güç Göstergeleri**: Hangi güçlerin aktif olduğunu ve kalan sürelerini gösterir
- **Ateş Etme Butonu**: Silahı ateşlemek için ekran üzerinde buton
- **Zıplama Butonu**: Zıplamak için ekran üzerinde buton
- **Oyun Duraklatma**: Oyunu duraklatmak için buton
- **Oyun Bitti Ekranı**: Oyun bittiğinde puanı ve yeniden başlatma seçeneğini gösterir
- **Ana Menü**: Oyun bitiminde ana menüye dönme seçeneği
- **Zıplama Güç Göstergesi**: Zıplama kuvvetini görsel olarak gösteren çubuk
- **Tutorial Bilgilendirme**: Oyun başında kontrol açıklamaları
- **Responsive Ana Menü**: Farklı ekran boyutlarına uyum sağlayan şık ana menü
- **Animasyonlu Butonlar**: Etkileşim sırasında animasyon gösteren UI elemanları
- **Gradient ve Gölge Efektleri**: Modern görünüm için görsel zenginlikler
- **XP ve Seviye Göstergesi**: Ana menüde mevcut oyuncu seviyesi ve XP durumu

## Seviye Sistemi Detayları
- **Seviye 1**: Acemi Koşucu - Standart oyun hızı, yalnızca temel engeller ve zayıf düşmanlar
- **Seviye 2**: Amatör Atlet - %20 daha fazla puan, %20 daha hızlı oyun, orta düzeyde düşmanlar
- **Seviye 3**: Hızlı Koşucu - %50 daha fazla puan, duvar engelleri, rampalar ve güçlü düşmanlar
- **Seviye 4**: Profesyonel Atlet - %80 daha fazla puan, %60 daha hızlı oyun, elit düşmanlar
- **Seviye 5**: Engel Ustası - %100 daha fazla puan, tüm engel tipleri ve düşman tipleri aktif
- **Seviye 6**: Efsane Koşucu - %150 daha fazla puan, maksimum zorluk ve boss düşmanlar

## Reklam Sistemi
- **Sahte Reklam Servisi**: Geçici bir çözüm olarak uygulanmış basit reklam servisi
- **Ara Reklam**: Oyun bitiminde gösterilen ara reklam
- **Ödüllü Reklam**: Ekstra ödül karşılığında izlenebilen reklam
- **Reklam Sayacı**: Reklam gösterimi için oyun sayısını takip eden sistem
- **Gelecek Entegrasyon**: Google AdMob veya başka bir reklam platformu entegrasyonu için hazırlık

## Uygulama Mimarisi ve Yapısı

Projemiz "Clean Architecture" prensiplerini takip ederek oluşturulmuştur ve şu ana modüllerden oluşmaktadır:

### Proje Klasör Yapısı
- **lib/**: Ana uygulama kodu
  - **main.dart**: Uygulamanın giriş noktası
  - **models/**: Veri modelleri ve state yönetimi
  - **domain/**: İş mantığı katmanı
    - **entities/**: Temel oyun varlıkları (karakterler, engeller, düşmanlar)
  - **presentation/**: Kullanıcı arayüzü katmanı
    - **pages/**: Ana oyun ekranları
    - **components/**: Oyun bileşenleri
      - **player/**: Oyuncu karakteri bileşenleri
      - **enemies/**: Düşman bileşenleri
      - **obstacles/**: Engel bileşenleri
      - **collectibles/**: Toplanabilir öğe bileşenleri
      - **background/**: Arkaplan bileşenleri
      - **particles/**: Parçacık efekt bileşenleri
      - **weapon/**: Silah ve mermi bileşenleri
      - **platforms/**: Platform bileşenleri
    - **widgets/**: Yeniden kullanılabilir UI bileşenleri
  - **services/**: Harici servisler (ses, reklam, vb.)
  - **utils/**: Yardımcı fonksiyonlar ve sınıflar

### Veri Yönetimi
- **Provider Paketi**: State yönetimi için kullanılmaktadır
  - **GameState**: Oyun durumu, skorlar, seviyeler ve temalar burada yönetilir
- **Shared Preferences**: Oyun verileri ve ayarlar için yerel depolama
  - **Yüksek Skor**: En yüksek puan yerel olarak saklanır
  - **Açılan Seviyeler**: Kilidi açılan seviyeler saklanır
  - **Açılan Temalar**: Satın alınan temalar saklanır
  - **Açılan Karakterler**: Satın alınan karakterler saklanır
  - **Altın Miktarı**: Toplam altın miktarı saklanır

### Oyun Motoru
- **Flame Framework**: Flutter üzerinde 2D oyun geliştirme için kullanılmaktadır
- **Flame Collision Detection**: Çarpışma tespiti için uygulanmıştır
- **Flame Components**: Oyun öğeleri için kullanılmaktadır
- **Flame Timer**: Zamanlayıcı ve döngüsel işlemler için kullanılmaktadır

## Test Sonuçları
- **Performans**: Optimizasyonlar sonrası tüm desteklenen platformlarda 60 FPS'nin üzerinde çalışma
- **Kullanıcı Geri Bildirimi**: Yeni insan karakteri, silah sistemi ve çok katmanlı oyun dünyası beğeni topladı
- **Dengeli Zorluk Seviyesi**: Oyun zamanla zorlaşırken adil bir öğrenme eğrisi sunuyor
- **Çapraz Platform Uyumluluk**: Mobil, web ve masaüstü platformlarda sorunsuz çalışma

## Gelecek Geliştirmeler
- **Çoklu Dil Desteği**: Farklı dillerde oyun arayüzü
- **Online Skor Tablosu**: Firebase veya başka bir hizmet kullanarak çevrimiçi skor rekabeti
- **Başarı Sistemi**: Oyuncuların açabileceği başarılar ve ödüller
- **Daha Fazla Karakter**: Yeni oynanabilir karakterler ve özel yetenekler
- **Günlük Görevler**: Daha fazla oyuncu katılımı için günlük hedefler
- **Boss Düşmanlar Geliştirme**: Özel aralıklarla ortaya çıkan, daha karmaşık davranışlara sahip düşmanlar
- **Sosyal Medya Entegrasyonu**: Başarıları ve yüksek skorları paylaşma özelliği
- **Ek Güç-Yükseltmeler**: Yeni güç-yükseltme tipleri
- **Eşyalar ve Yükseltmeler Mağazası**: Daha fazla özelleştirme ve strateji için
- **Google Play Games / Game Center Entegrasyonu**: Platform özgü oyun hizmetleri

## Son Güncelleme Notları (Mayıs, 2024)
- Ses sistemi ve reklam servisi entegrasyonu tamamlandı
- Performans optimizasyonları yapıldı
- Tema mağazası genişletildi
- Görsel efektler iyileştirildi
- Seviye sistemi düzenlendi
- Karakter kontrolleri daha hassas hale getirildi
- Silah ve mermi sistemi geliştirildi
- Düşman yapay zekası iyileştirildi
- Büyük ve küçük ekranlarda responsiveness iyileştirildi
- Flutter ve Flame framework'ünün son sürümlerine güncelleme yapıldı
