# Proes PDF Manager

Proes Teknik için çevrimdışı PDF arşivi.

## Kullanım
- PWA sürümü `docs/` klasöründedir.
- GitHub Pages ayarlarında **Deploy from a branch** seçilip `main` ve `/docs` seçildiğinde web uygulaması yayınlanır.
- iPhone'da yayınlanan adres Safari ile açılır; Paylaş > Ana Ekrana Ekle seçilir.
- PDF dosyaları tarayıcının IndexedDB alanında cihazda saklanır; uygulamanın ilk açılışından sonra uygulama kabuğu çevrimdışı açılabilir.

## Özellikler
- Klasör ve alt klasörler
- PDF ekleme ve cihazda saklama
- PDF açma, yeniden adlandırma ve silme
- Çevrimdışı uygulama kabuğu (service worker)

## Notlar
- Bu sürüm App Store uygulaması değildir; iPhone ana ekranından çalışan web uygulamasıdır.
- Tarayıcı verileri temizlenirse yerel PDF arşivi silinebilir. Önemli belgelerin ayrıca yedeğini tutun.
- iOS depolama alanı yönetimi nedeniyle çok büyük arşivlerde tarayıcı kısıtlamaları olabilir.
- Flutter kaynak kodu ve Android/iOS yerel derleme yapılandırması korunmuştur.
