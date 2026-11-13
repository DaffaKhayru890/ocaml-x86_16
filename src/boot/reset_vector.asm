; Letakkan instruksi reset tepat pada offset FFF0h di dalam ROM.
times RESET_VECTOR_OFFSET - ($ - $$) db 0xFF
reset_vector:
    FIRMWARE_FAR_JUMP FIRMWARE_SEGMENT, firmware_entry
times ROM_SIZE - ($ - $$) db 0xFF
