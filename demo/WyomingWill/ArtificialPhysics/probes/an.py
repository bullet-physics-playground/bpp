import wave, numpy as np, sys
import os
S=os.environ.get('PROBES','.')
p=sys.argv[1]
for e in sys.argv[2:]:
  w=wave.open(f'{S}/{p}_e{e}.wav'); sr=w.getframerate(); n=w.getnframes()
  x=np.frombuffer(w.readframes(n),dtype='<i2').reshape(-1,2).astype(float)/32768
  m=x.mean(1); hop=sr//4
  db=20*np.log10(np.array([np.sqrt((m[i:i+hop]**2).mean()) for i in range(0,len(m)-hop,hop)])+1e-9)
  q=db[120:]
  print(f"e={e}: peak={np.abs(x).max():.2f} takeoff {db[:60].mean():.1f} dB | after 30 s: median {np.median(q):.1f}, p99 {np.percentile(q,99):.1f}, max {q.max():.1f}; p99-median {np.percentile(q,99)-np.median(q):.1f} dB, max-median {q.max()-np.median(q):.1f} dB")
