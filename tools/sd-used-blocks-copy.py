# Read-only: copies only allocated ext4 blocks from SRC into a sparse image DST.
# Read-only. Usage: python3 -I tools/sd-used-blocks-copy.py /dev/rdiskNs2 rootfs.img
# Needs read permission on the raw partition (e.g. `sudo chmod o+r /dev/rdiskNs2`, reset on unplug).
import struct, sys, os, time
SRC, DST = sys.argv[1], sys.argv[2]
src = open(SRC, 'rb', buffering=0)
def rd(off, n):
    # raw device needs 512-aligned reads
    a = off - off % 512; m = ((off + n - a + 511)//512)*512
    src.seek(a); d = src.read(m); return d[off-a:off-a+n]
sb = rd(1024, 1024); g = lambda f,o: struct.unpack_from(f, sb, o)[0]
bc, bs, bpg = g('<I',4), 1024 << g('<I',0x18), g('<I',0x20)
ngroups = (bc + bpg - 1)//bpg
gdt = rd(bs, ngroups*32)
runs = []
for i in range(ngroups):
    bb, flags = struct.unpack_from('<I', gdt, i*32)[0], struct.unpack_from('<H', gdt, i*32+0x12)[0]
    base = i*bpg; n = min(bpg, bc-base)
    if flags & 0x2:  # BLOCK_UNINIT: only possible sb/gdt backups at start
        runs.append((base, min(n, 1024))); continue
    bm = rd(bb*bs, bs)
    j = 0
    while j < n:
        if bm[j>>3] >> (j&7) & 1:
            k = j
            while k < n and bm[k>>3] >> (k&7) & 1: k += 1
            runs.append((base+j, k-j)); j = k
        else: j += 1
total = sum(n for _,n in runs)
print(f'groups {ngroups} runs {len(runs)} copying {total*bs/1e9:.2f} GB', flush=True)
out = open(DST, 'wb'); out.truncate(bc*bs)
done = 0; t0 = time.time(); CH = 1024  # 4 MB chunks
for start, n in runs:
    off = 0
    while off < n:
        c = min(CH, n-off)
        src.seek((start+off)*bs); data = src.read(c*bs)
        out.seek((start+off)*bs); out.write(data)
        off += c; done += c
    if done % 25600 < CH or start == runs[-1][0]:
        el = time.time()-t0
        print(f'{done*bs/1e9:.2f}/{total*bs/1e9:.2f} GB  {done*bs/1e6/max(el,1):.1f} MB/s', flush=True)
out.close(); print('DONE', flush=True)
