# Oyun Projesi - PRD

## Proje Özeti

"Endless Runner" oyunumuz, kullanıcılara eğlenceli ve bağımlılık yapıcı bir oyun deneyimi sunmak amacıyla geliştirilmiştir. Oyun, Flutter ve Flame oyun motoru kullanılarak oluşturulmuştur. Oyuncular, silahlı bir insan karakteri ile rastgele ortaya çıkan düşmanlarla mücadele ederek, engelleri atlayarak, ateş ederek, güç-yükseltmeleri toplayarak ve puanlarını en üst seviyeye çıkararak ilerlemektedir.

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
- **Silah Çeşitleri**: Tabanca, tüfek, lazer gibi farklı özelliklere sahip silahlar
- **Karakter Kostümleri**: Farklı görünüm seçenekleri ve özellikler
- **Karakter Güçlendirmeleri**: Oyun içi geliştirebilen karakter özellikleri

### Düşman Sistemi
- **Rastgele Düşman Oluşumu**: Oyun sırasında rastgele düşmanlar ortaya çıkar
- **Farklı Düşman Tipleri**: Yavaş, hızlı, zıplayan, uçan gibi çeşitli düşman tipleri
- **Zorluk Bazlı Düşman Dağılımı**: İleri seviyelerde daha zorlu düşmanlar
- **Düşman Sağlık Sistemleri**: Farklı düşmanlar için değişken can miktarları
- **Düşman Ödülleri**: Öldürülen düşmanlardan düşen ödüller (mermi, puan, can, vb.)

### Mermi Sistemi
- **Sınırlı Mermi**: Oyuncu sınırlı sayıda mermiye sahiptir
- **Mermi Toplayıcılar**: Oyun dünyasında bulunabilecek mermi kutuları
- **Farklı Mermi Tipleri**: Normal, hızlı, patlayıcı gibi çeşitli mermi türleri
- **Mermi Göstergesi**: Ekranda kalan mermi sayısını gösteren arayüz

### Güç-Yükseltmeler
- **Mıknatıs**: Civardaki paraları oyuncuya çeker (8 saniye)
- **Kalkan**: Geçici dokunulmazlık sağlar (5 saniye)
- **Yavaş Çekim**: Oyun hızını yavaşlatır (5 saniye)
- **Skor Artırıcı**: Ekstra puan ve combo sağlar
- **Ekstra Can**: Oyuncuya bir can ekler (maksimum 3)
- **Mermi Paketi**: Ekstra mermi sağlar
- **Güçlü Ateş**: Geçici olarak daha güçlü mermiler (5 saniye)

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

### Tema Sistemi
- **Özelleştirilebilir Temalar**: Farklı renk şemaları ve görsel stiller
- **Tema Mağazası**: Oyunda kazanılan altınlarla satın alınabilen temalar
- **Aktif Tema Gösterimi**: Mevcut seçili temayı gösteren arayüz
- **Tema Önizleme**: Satın almadan önce temaları önizleme imkanı
- **Kilitli Temalar**: Oyun ilerleyişi ile açılan veya satın alınabilen temalar

### Seviye Sistemi
- **Tecrübe Puanı (XP)**: Oyun içi puanların bir kısmı XP olarak kaydedilir
- **Seviye İlerleme Çubuğu**: Mevcut XP durumunu görsel olarak gösteren çubuk
- **Seviye Ödülleri**: Her seviyede artan puan çarpanı ve özel içerikler
- **Seviye Tabanlı Zorluk**: Üst seviyelerde daha hızlı ve zor oyun deneyimi
- **Seviye Seçim Ekranı**: Açılan seviyeleri görüntüleme ve seçme imkanı
- **Seviye Atlama Bildirimi**: Yeni seviyeye ulaşıldığında özel bildirim
- **Seviye Bazlı Engeller**: Üst seviyelerde daha karmaşık engel tipleri
- **Seviye Bazlı Düşmanlar**: Üst seviyelerde daha tehlikeli düşman çeşitleri

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

## Teknik Özellikler
- **Flame Oyun Motoru**: 2D oyun geliştirme için Flutter'a entegre framework
- **Çarpışma Sistemi**: Hassas çarpışma algılama ve tepkileri
- **Performans Optimizasyonu**: Akıcı oyun deneyimi için optimize edilmiş kod
- **Duyarlı Kullanıcı Girişi**: Basılı tutma, dokunma ve tepki verme için gelişmiş giriş sistemi
- **Yüksek Skor Saklama**: Oyuncunun en yüksek skorunu kaydetme ve gösterme
- **Responsive Tasarım**: Farklı ekran boyutlarına uyum sağlayan arayüz
- **Dokunuş Hareketi Tanıma**: Kaydırma ve dokunma hareketleri için gelişmiş tanıma
- **Obje Tipi Bazlı Çarpışma Kutuları**: Farklı engel ve düşman tipleri için optimize edilmiş çarpışma kutuları
- **İlerleme Kayıt Sistemi**: Oyuncu seviyesi ve XP bilgisini yerel depolamada saklama
- **Silah Fiziği**: Gerçekçi ateş etme mekanikleri ve mermi yolu fizikleri
- **Düşman Yapay Zekası**: Basit düşman hareket ve saldırı algoritmaları
- **Katmanlı Dünya Oluşturma**: Rastgele ve dengeli çok katmanlı dünya oluşturma
- **Mermi Sayaç Sistemi**: Mermi sayısını takip eden ve görselleştiren sistem

## Ses Sistemi
- **Farklı Ses Efektleri**: Zıplama, çift zıplama, kayma, dash, ateş etme, mermi toplama, çarpışma ve güç-yükseltme aktivasyon sesleri
- **Düşman Sesleri**: Düşman hareketleri, saldırıları ve ölüm sesleri
- **Silah Sesleri**: Farklı silahlar için özel atış sesleri
- **Müzik Parçaları**: Menü müziği, oyun içi müzik ve oyun sonu müziği
- **Ses Ayarları**: Kullanıcıların müzik ve ses efektlerini ayrı ayrı açıp kapatabilmesi
- **Dinamik Ses**: Oyun hızı arttıkça müzik temposunun hafifçe artması
- **Kayıt Sistemi**: Kullanıcının ses tercihlerinin yerel depolamada saklanması
- **Ses Önbelleği**: Performans iyileştirme için sık kullanılan seslerin önbelleğe alınması
- **Kesintisiz Geçişler**: Farklı oyun durumları arasında müziğin kesintisiz geçişi

## Parçacık Sistemi
- **Temel Parçacık Sınıfı**: Hız ve renk gibi ortak özelliklere sahip temel parçacık yapısı
- **Farklı Parçacık Türleri**: Dairesel, yıldız, konfeti, duman ve koşma parçacıkları
- **Zıplama Efektleri**: Zıplama ve çift zıplama sırasında farklı görsel parçacık efektleri
- **Ateş Etme Efektleri**: Silah ateşlendikçe namlu parlaması ve duman efektleri
- **Mermi İzi Efektleri**: Mermilerin çarptığı yüzeylerde iz ve parçacık efektleri
- **Düşman Vurulma Efektleri**: Düşmanlar vurulduğunda kan veya patlama efektleri
- **Düşman Ölüm Efektleri**: Düşmanlar öldüğünde özel parçacık efektleri
- **Toplanabilir Efektleri**: Farklı toplanabilir nesneler için özel renkli parçacık patlamaları
- **Çarpışma Efektleri**: Engele çarpıldığında kırmızı patlama ve duman parçacıkları
- **Dash Hareket Çizgileri**: Dash sırasında hareket çizgilerini simgeleyen parçacıklar
- **Kayma İzi**: Kayma hareketi sırasında zemin üzerinde toz efekti
- **Konfeti Patlamaları**: Seviye atlandığında ve yüksek skor kırıldığında konfeti patlaması
- **Oyun Sonu Efektleri**: Oyun bitiminde özel efektler ve parçacık efektleri
- **Koşma Tozu**: Koşma sırasında karakterin arkasında hafif toz efekti
- **Yıldız Patlamaları**: Güç yükseltmeleri ve özel olaylarda renkli yıldız patlaması
- **Dinamik Boyutlandırma**: Parçacıkların zamanla solması ve küçülmesi
- **Performans Optimizasyonu**: Maksimum parçacık sınırı ile düşük sistemlerde performans garantisi

## Performans Optimizasyonları
- **Görsel Öğe Sınırlaması**: Ekrandaki grafik öğelerinin sayısı optimize edildi
- **Lazy Initialization**: Nesneler sadece ihtiyaç duyulduğunda oluşturulur
- **Render Optimizasyonu**: Ekran dışındaki nesneler render edilmiyor
- **Basitleştirilmiş Şekiller**: Karmaşık eğriler yerine basit çizimler kullanılıyor
- **Önbelleğe Alınmış Çizimler**: Sık kullanılan şekiller önceden hazırlanıyor
- **Obje Havuzu**: Nesnelerin yeniden kullanımı için optimize edilmiş sistem
- **Detay Seviyesi Kontrolü**: Uzaktaki veya önemsiz nesnelerde daha az detay
- **Çarpışma Kutusu Optimizasyonu**: Basitleştirilmiş çarpışma algılama
- **Görsel Efekt Yönetimi**: Sadece görünür olduğunda efekt render etme
- **Dağ ve Bulut Sayısı Azaltma**: Benzer görsel etkiyi daha az nesneyle sağlama
- **3B Efektleri Optimizasyonu**: Performans için hafifletilmiş 3B görünümlü 2D çizimler
- **Shader ve Gradient Optimizasyonu**: Daha verimli shader kullanımı
- **Çimen Detaylarının Azaltılması**: Minimum çimen öğesiyle maksimum görsel etki
- **Seviye Bazlı Engel Optimizasyonu**: Farklı zorluk seviyelerinde optimum engel sayısı
- **Düşman Sayısı Kontrolü**: Performans düşmemesi için ekranda maksimum düşman sayısı sınırlaması
- **Mermi Fizik Optimizasyonu**: Basitleştirilmiş mermi fizik hesaplamaları

## Gerçekleştirilmiş Geliştirmeler
- **İnsan Karakteri**: Elinde silah taşıyan insan karakteri eklendi
- **Düşman Sistemi**: Rastgele ortaya çıkan düşmanlar
- **Can Sistemi**: Düşmanlara ve engellere temas edince can azalması
- **Katmanlı Oyun Dünyası**: Zıplayarak geçilebilen platformlar
- **Ateş Etme Mekanikleri**: Düşmanları öldürmek için ateş etme
- **Mermi Sistemi**: Sınırlı mermi ve mermi toplama mekanikleri
- **Tema Mağazası**: Oyun içi para ile satın alınabilir farklı temalar
- **Özel Engeller**: Görsel olarak zenginleştirilmiş, efekt ve animasyonlu engeller
- **Yüksek Skor Kaydı**: Yerel depolamada saklanan en yüksek puan sistemi
- **Responsive Arayüz**: Farklı ekran boyutlarına tam uyumlu kullanıcı arayüzü
- **Engel Çarpışma İyileştirmeleri**: Engel tiplerine özel çarpışma kutuları
- **Performans Optimizasyonları**: FPS artıran kapsamlı grafik ve render iyileştirmeleri
- **Chrome Basılı Tutma Düzeltmesi**: Web tarayıcılarında oyun kontrollerinin optimizasyonu
- **Görsel Dil Değişimi**: Arayüzün İngilizce'den Türkçe'ye çevrilmesi
- **Oyun Sonu İyileştirmeleri**: Ana menüye dönüş ve yeniden oynama seçenekleri
- **Seviye Sistemi**: XP toplama ve seviyelerin kilidi açılması sistemi
- **Seviye Seçim Ekranı**: Açılmış seviyeler arasında seçim yapabilme
- **Ses Sistemi**: Oyun müzikleri ve efektleri tam entegrasyonu
- **Ayarlar Menüsü**: Ses ve müzik açma/kapama kontrolleri
- **Özel Efektler ve Parçacık Sistemleri**: Oyun içindeki olaylara göre dinamik parçacık patlamaları, yıldız, konfeti, duman efektleri ve koşma sırasında ayak izleri

## Seviye Sistemi Detayları
- **Seviye 1**: Acemi Koşucu - Standart oyun hızı, yalnızca temel engeller ve zayıf düşmanlar
- **Seviye 2**: Amatör Atlet - %20 daha fazla puan, %20 daha hızlı oyun, orta düzeyde düşmanlar
- **Seviye 3**: Hızlı Koşucu - %50 daha fazla puan, duvar engelleri, rampalar ve güçlü düşmanlar
- **Seviye 4**: Profesyonel Atlet - %80 daha fazla puan, %60 daha hızlı oyun, elit düşmanlar
- **Seviye 5**: Engel Ustası - %100 daha fazla puan, tüm engel tipleri ve düşman tipleri aktif
- **Seviye 6**: Efsane Koşucu - %150 daha fazla puan, maksimum zorluk ve boss düşmanlar

## Gelecek Geliştirmeler
- **Şerit Değiştirme Sistemi**: Sağa/sola kaydırarak şerit değiştirebilme
- **Daha Geniş Silah Çeşitliliği**: Farklı silah tipleri ve güçlendirmeleri
- **Boss Düşmanlar**: Belirli aralıklarla ortaya çıkan özel güçlü düşmanlar
- **Karakter Özelleştirme**: Farklı karakterler ve görünümler
- **Seviye Sistemi Genişletme**: Daha fazla seviye ve daha özel ödüller
- **Ses Efektleri ve Müzik Genişletme**: Farklı seviyelere özel müzik ve efektler
- **Yüksek Skor Tablosu**: Çevrimiçi yüksek skor rekabeti
- **Başarılar ve Ödüller**: Oyuncuya motivasyon sağlayacak hedefler
- **İlerleme Sistemi**: Oyuncu becerilerinin gelişimine dayalı açılan özellikler
- **Görev Sistemi**: Günlük ve haftalık tamamlanabilir görevler
- **Aşamalı Zorluk Sistemi**: Oyun ilerledikçe açılan yeni engel ve düşman tipleri
- **Online Çok Oyunculu Mod**: Diğer oyuncularla yarışma imkanı

## Test Sonuçları
- **Performans**: Optimizasyonlar sonrası tüm desteklenen platformlarda 60 FPS'nin üzerinde çalışma
- **Kullanıcı Geri Bildirimi**: Yeni insan karakteri, silah sistemi ve çok katmanlı oyun dünyası beğeni topladı
- **Dengeli Zorluk Seviyesi**: Oyun zamanla zorlaşırken adil bir öğrenme eğrisi sunuyor
- **Silah Mekanikleri**: Ateş etme ve düşman öldürme mekanikleri akıcı ve tatmin edici
- **Düşman Sistemi**: Rastgele düşman oluşturma sistemi test edildi ve dengeli bulundu
- **Mermi Sistemi**: Sınırlı mermi ve mermi toplama mekanikleri iyi dengelenmiş bulundu
- **Çapraz Platform Uyumluluk**: Mobil, web ve masaüstü platformlarda sorunsuz çalışma
- **Tarayıcı Uyumluluğu**: Chrome, Firefox ve Safari'de test edildi ve optimize edildi
- **Görsel Performans**: Optimize edilen arka plan ve engel tasarımları ile daha iyi görsel deneyim
- **Responsive Tasarım**: Farklı ekran boyutlarında sorunsuz ölçekleme
- **Seviye Sistemi Testi**: XP kazanma ve seviye atlama mekanikleri düzgün çalışıyor
- **Ses Sistemi Testi**: Tüm ses efektleri ve müzikler tüm platformlarda gecikme olmadan çalışıyor
- **Ayarlar Menüsü**: Ses ve müzik ayarları düzgün kaydediliyor ve uygulanıyor
- **Parçacık Sistemi Testi**: Farklı cihazlarda parçacık efektleri performans düşüşü olmadan akıcı şekilde çalışıyor

## Teknik Notlar
- **Flutter Versiyonu**: 3.0.0+
- **Flame Versiyonu**: 1.28.0
- **Provider Versiyonu**: 6.0.5
- **Dart SDK Versiyonu**: '>=3.0.0 <4.0.0'
- **SharedPreferences Versiyonu**: 2.2.1
- **AudioPlayers Versiyonu**: 6.4.0
- **Flutter Cube Versiyonu**: 0.1.1
- **Just Audio Versiyonu**: 0.9.36
- **Minimum API Gereksinimleri**: Android API Level 16+, iOS 9.0+
