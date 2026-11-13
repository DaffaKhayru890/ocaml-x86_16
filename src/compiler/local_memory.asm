; Menghapus bitmap inisialisasi seluruh slot lokal.
; Masukan: DS menunjuk memori kerja compiler.
; Keluaran: delapan byte bitmap bernilai nol; CF=0.
; Register berubah: BX dan CX dipulihkan.
; Kesalahan: tidak ada.
; Alur: tulis nol ke setiap byte bitmap menggunakan penghitung 8086.
clear_local_init_bitmap:
    push bx
    push cx
    xor bx, bx
    mov cx, WORK_LOCAL_INIT_SIZE
.clear_byte:
    mov byte [ds:WORK_LOCAL_INIT_BITMAP + bx], 0
    inc bx
    loop .clear_byte
    pop cx
    pop bx
    clc
    ret

; Memastikan indeks slot berada di antara nol dan 63.
; Masukan: AL berisi indeks slot lokal.
; Keluaran: CF=0 jika slot valid.
; Register berubah: AX pada jalur error dan flag; AL dipertahankan jika valid.
; Kesalahan: slot di luar batas mencatat ERR_INVALID_LOCAL_SLOT.
; Alur: bandingkan indeks tanpa tanda dengan jumlah slot maksimum.
validate_local_slot:
    cmp al, MAX_LOCAL_SLOTS
    jb .valid
    mov ax, ERR_INVALID_LOCAL_SLOT
    call compiler_record_error
    ret
.valid:
    clc
    ret

; Menghitung offset slot pada segment data runtime.
; Masukan: AL berisi indeks slot yang akan dihitung.
; Keluaran: AX berisi offset; CF=0 jika rentang slot aman.
; Register berubah: AX dan flag.
; Kesalahan: slot invalid atau rentang melewati LOCAL_SLOT_END.
; Alur: validasi indeks, kalikan ukuran slot, lalu tambahkan offset dasar.
calculate_local_address:
    call validate_local_slot
    jc .failed
    xor ah, ah
    shl ax, 1
    add ax, LOCAL_SLOT_BASE
    cmp ax, LOCAL_SLOT_END - LOCAL_SLOT_SIZE
    jbe .valid
    mov ax, ERR_LOCAL_MEMORY_OVERFLOW
    call compiler_record_error
    ret
.valid:
    clc
    ret
.failed:
    stc
    ret

; Menandai slot lokal sebagai telah diinisialisasi.
; Masukan: AL berisi indeks slot lokal.
; Keluaran: bit slot bernilai satu; CF=0 jika berhasil.
; Register berubah: AX, BX, CX dipulihkan; flag menunjukkan hasil.
; Kesalahan: indeks di luar batas mencatat ERR_INVALID_LOCAL_SLOT.
; Alur: byte bitmap adalah indeks dibagi delapan dan bit adalah sisanya.
set_local_initialized:
    push ax
    push bx
    push cx
    call validate_local_slot
    jc .failed
    mov bl, al
    mov cl, 3
    shr bl, cl
    mov cl, al
    and cl, 7
    mov al, 1
    shl al, cl
    or byte [ds:WORK_LOCAL_INIT_BITMAP + bx], al
    clc
    jmp .done
.failed:
    stc
.done:
    pop cx
    pop bx
    pop ax
    ret

; Memeriksa apakah slot lokal telah ditulis sebelumnya.
; Masukan: AL berisi indeks slot lokal.
; Keluaran: CF=0 jika inisialisasi ditemukan.
; Register berubah: AX, BX, CX dipulihkan; flag menunjukkan hasil.
; Kesalahan: slot invalid atau belum diinisialisasi.
; Alur: uji bit slot pada bitmap sebelum LOAD_LOCAL diizinkan.
check_local_initialized:
    push ax
    push bx
    push cx
    call validate_local_slot
    jc .failed
    mov bl, al
    mov cl, 3
    shr bl, cl
    mov cl, al
    and cl, 7
    mov al, 1
    shl al, cl
    test byte [ds:WORK_LOCAL_INIT_BITMAP + bx], al
    jnz .initialized
    mov ax, ERR_UNINITIALIZED_LOCAL
    call compiler_record_error
    jmp .done
.initialized:
    clc
    jmp .done
.failed:
    stc
.done:
    pop cx
    pop bx
    pop ax
    ret
