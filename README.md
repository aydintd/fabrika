### Gereksinimler
 
-   [Packer](http://www.packer.io/downloads.html)
sdsa
-   VirtualBox

-   Rake

### Kullanım

-   Öntanımlı sanalı inşa et

    ```sh
    $ rake build
    ```

-   Tüm Debian sanallarını inşa et

    ```sh
    $ rake build[debian,all]
    ```

-   Belirli bir dizindeki sanalı inşa et

    ```sh
    $ cd «dizin»
    $ rake build
    ```

### Ortam Değişkenleri

-   `PACKER_CACHE_DIR` → Önbellek dizini

-   `PACKER_OUT_DIR` → Üretilen dosyaların taşınacağı dizin

-   `PACKER_LOG_DIR` → Günlük dizini

### Yeni Şablon Geliştirme

-   Dizin oluştur

    ```sh
    $ mkdir «dağıtım»-«profil»
    $ cd «dağıtım»-«profil»
    $ cp ../_/«dağıtım»/template.json
    $ touch template.sh
    ```

-   Şablon dosyasını düzenle

-   Kabuk betiğini (`template.sh`) düzenle

-   Şablonu denetleyerek üret

    ```sh
    $ rake update
    ```
