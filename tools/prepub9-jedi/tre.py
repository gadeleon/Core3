import os, struct, zlib, sys, json
# Folder holding the client .tre files; override with SWG_TRE=/path/to/client
TRE=os.environ.get("SWG_TRE","/tre")
ORDER=["default_patch.tre","hotfix_13_1_00.tre","hotfix_sku1_12_1_00.tre","patch_sku1_14_00.tre","patch_14_00.tre","patch_sku1_13_00.tre","patch_13_00.tre","patch_sku1_12_00.tre","patch_12_00.tre","patch_11_03.tre","data_sku1_07.tre","patch_11_02.tre","data_sku1_06.tre","patch_11_01.tre","patch_11_00.tre","data_sku1_05.tre","data_sku1_04.tre","data_sku1_03.tre","data_sku1_02.tre","data_sku1_01.tre","data_sku1_00.tre","patch_10.tre","patch_09.tre","patch_08.tre","patch_07.tre","patch_06.tre","patch_05.tre","patch_04.tre","patch_03.tre","patch_02.tre","patch_01.tre","patch_00.tre","data_other_00.tre","data_static_mesh_01.tre","data_static_mesh_00.tre","data_texture_07.tre","data_texture_06.tre","data_texture_05.tre","data_texture_04.tre","data_texture_03.tre","data_texture_02.tre","data_texture_01.tre","data_texture_00.tre","data_skeletal_mesh_01.tre","data_skeletal_mesh_00.tre","data_animation_00.tre","data_sample_04.tre","data_sample_03.tre","data_sample_02.tre","data_sample_01.tre","data_sample_00.tre","data_music_00.tre","bottom.tre"]
class Tre:
    def __init__(s,p):
        s.f=open(p,"rb"); h=s.f.read(36)
        _,_,n,to,tc,ts,bc,bs,_=struct.unpack("<4s4s7I",h)
        s.f.seek(to); t=s.f.read(ts); t=zlib.decompress(t) if tc else t
        nm=s.f.read(bs); nm=zlib.decompress(nm) if bc else nm
        s.e={}
        for i in range(n):
            _,ln,off,c,cl,no=struct.unpack_from("<6I",t,i*24)
            s.e[nm[no:nm.index(b"\0",no)].decode()]=(ln,off,c,cl)
    def read(s,name):
        ln,off,c,cl=s.e[name]
        if ln==0: return b""
        s.f.seek(off); d=s.f.read(cl if c else ln)
        return zlib.decompress(d) if c else d
_c={}
def arc(n):
    if n not in _c: _c[n]=Tre(os.path.join(TRE,n))
    return _c[n]
def versions(name):
    return [(a,arc(a).e[name][0]) for a in ORDER if os.path.exists(os.path.join(TRE,a)) and name in arc(a).e]
def get(name):
    for a in ORDER:
        if os.path.exists(os.path.join(TRE,a)) and name in arc(a).e: return a,arc(a).read(name)
    return None,None
def find(sub):
    out={}
    for a in ORDER:
        if not os.path.exists(os.path.join(TRE,a)): continue
        for n in arc(a).e:
            if sub(n): out.setdefault(n,[]).append(a)
    return out
# IFF
def iff(d,p=0,end=None):
    end=len(d) if end is None else end; out=[]
    while p+8<=end:
        tag=d[p:p+4].decode('latin1'); sz=struct.unpack(">I",d[p+4:p+8])[0]
        if tag=="FORM":
            ft=d[p+8:p+12].decode('latin1'); out.append(("FORM",ft,iff(d,p+12,p+8+sz)))
        else: out.append((tag,None,d[p+8:p+8+sz]))
        p+=8+sz
    return out
def chunks(tree,tag):
    for t,ft,c in tree:
        if t=="FORM": yield from chunks(c,tag)
        elif t==tag: yield c
def datatable(d):
    tr=iff(d)
    cols=next(chunks(tr,"COLS")); typ=next(chunks(tr,"TYPE")); rows=next(chunks(tr,"ROWS"))
    nc=struct.unpack_from("<I",cols,0)[0]; names=cols[4:].split(b"\0")[:nc]; names=[x.decode() for x in names]
    types=[x.decode() for x in typ.split(b"\0")[:nc]]
    nr=struct.unpack_from("<I",rows,0)[0]; p=4; R=[]
    for _ in range(nr):
        r=[]
        for t in types:
            k=t[0].lower()
            if k in "ihbe": r.append(struct.unpack_from("<i",rows,p)[0]); p+=4
            elif k=="f": r.append(round(struct.unpack_from("<f",rows,p)[0],4)); p+=4
            elif k in "sc": q=rows.index(b"\0",p); r.append(rows[p:q].decode('latin1')); p=q+1
            else: raise Exception("type "+t)
        R.append(r)
    return names,types,R
def stf(d):
    _,_,_,cnt=struct.unpack_from("<IBII",d,0); p=13; v={}
    for _ in range(cnt):
        i,_,nc=struct.unpack_from("<III",d,p); p+=12; v[i]=d[p:p+nc*2].decode("utf-16-le"); p+=nc*2
    o={}
    for _ in range(cnt):
        i,nl=struct.unpack_from("<II",d,p); p+=8; o[d[p:p+nl].decode()]=v[i]; p+=nl
    return o
