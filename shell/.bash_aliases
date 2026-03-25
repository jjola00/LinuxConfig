# eCryptfs aliases for ~/dot
alias mountdot='sudo mount -t ecryptfs -o key=passphrase,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_unlink_sigs,ecryptfs_sig=0964a844f6b63502 ~/dot ~/dot'
alias umountdot='sudo umount ~/dot'
alias cp2dot='cp ~/pics ~/dot/'
