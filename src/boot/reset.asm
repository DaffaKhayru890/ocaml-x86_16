; Entry point menerima kendali dari far jump pada reset vector.
firmware_entry:
    cli
    cld
    jmp initialize_segments
