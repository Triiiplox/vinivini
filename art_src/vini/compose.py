"""Monta o Vini a partir das peças (pose neutra) para calibrar proporções contra a ficha aprovada."""
import json, sys
from PIL import Image
import numpy as np
P='parts/'
def load(n): return Image.open(P+n+'.png').convert('RGBA')
def split_arm(n):
    im=load(n); a=np.array(im).astype(float)
    h=a.shape[0]; lum=(a[:,:,:3].mean(2)*(a[:,:,3]>128)).sum(1)/np.maximum(1,(a[:,:,3]>128).sum(1))
    lo,hi=int(h*0.38),int(h*0.62); cut=lo+int(np.argmin(lum[lo:hi]))
    return im.crop((0,0,im.width,cut+6)), im.crop((0,cut-6,im.width,h)), cut
CFG=json.load(open('rig_layout.json'))
def render(cfg, size=(900,1100), bg=(150,152,160,255)):
    can=Image.new('RGBA',size,bg)
    items=[]
    for name,c in cfg['parts'].items():
        if c.get('hide'): continue
        src=c.get('src',name)
        if src.startswith('split:'):
            _,arm,which=src.split(':'); up,lo,_=split_arm(arm); im=up if which=='up' else lo
        else: im=load(src)
        s=c['scale']; im=im.resize((max(1,int(im.width*s)),max(1,int(im.height*s))),Image.LANCZOS)
        if c.get('flip'): im=im.transpose(Image.FLIP_LEFT_RIGHT)
        if c.get('rot'): im=im.rotate(c['rot'],resample=Image.BICUBIC,expand=True)
        items.append((c['z'],im,c['x'],c['y']))
    for z,im,x,y in sorted(items,key=lambda t:t[0]):
        can.alpha_composite(im,(int(x-im.width/2),int(y-im.height/2)))
    return can
if __name__=='__main__':
    out=render(CFG)
    ref=Image.open('vini_character_sheet_v1.png').convert('RGBA').crop((430,10,740,630))
    ref=ref.resize((int(ref.width*out.height/ref.height),out.height))
    W=Image.new('RGBA',(out.width+ref.width,out.height),(150,152,160,255)); W.alpha_composite(out,(0,0)); W.alpha_composite(ref,(out.width,0))
    W.convert('RGB').resize((W.width//2,W.height//2)).save(sys.argv[1])
