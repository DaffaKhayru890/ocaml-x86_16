# Register segmen dan real mode

## Segment:offset

Alamat real-mode klasik dibentuk sebagai `segment * 16 + offset`.
Misalnya `5000:FFFC` menunjuk `50000h + FFFCh = 5FFFCh`.
Rentang dari satu segment sepanjang 64 KiB dapat overlap dengan segment lain;
segment bukan proteksi atau alokasi memori tersendiri.

## Register firmware

- **CS** menentukan segmen instruksi. Reset vector memakai far jump untuk
  memuat CS `F000h` dan IP `0000h`; firmware tidak menulis CS secara langsung.
- **DS** dan **ES** diatur ke `F000h`, sehingga referensi data default menuju
  alias ROM firmware.
- **SS** diatur ke `5000h` sebagai basis stack.
- **SP** diatur ke `FFFEh`. CALL mendorong alamat balik dan RET mengambilnya.
- **AX** hanya register sementara untuk memindahkan konstanta ke register
  segmen; instruksi MOV segment tidak menerima immediate secara langsung.

Interrupt maskable dimatikan sebelum SS/SP disiapkan. Penulisan SS diikuti
langsung penulisan SP dan tidak ada instruksi yang dapat memakai stack di
antara keduanya. Entry memakai JMP ke routine inisialisasi, bukan CALL,
karena stack belum ada.

## Batasan mode

Walaupun instruksi firmware disusun 16-bit, prosesor modern melewati keadaan
reset khusus sebelum eksekusi real-mode normal. Far jump memindahkan kendali
ke alias rendah agar CS:IP normal dipakai. Pengaturan A20, protected mode,
paging, ataupun layanan BIOS tidak diperlukan dan tidak dilakukan di phase ini.
