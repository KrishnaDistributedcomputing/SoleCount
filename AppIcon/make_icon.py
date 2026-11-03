from PIL import Image, ImageDraw, ImageFilter
S=1024
img=Image.new("RGB",(S,S))
d=ImageDraw.Draw(img)
# vertical gradient orange->red
for y in range(S):
    t=y/S
    r=int(255*(1-t)+230*t); g=int(140*(1-t)+57*t); b=int(40*(1-t)+70*t)
    d.line([(0,y),(S,y)],fill=(r,g,b))
# sneaker silhouette (white)
W=(255,255,255)
shoe=[(170,600),(190,430),(250,400),(330,420),(400,470),(470,520),(560,560),(700,600),(820,640),(870,690),(860,740),(170,740)]
d.polygon(shoe,fill=W)
# sole
d.rounded_rectangle([150,730,880,800],radius=35,fill=(40,40,50))
# laces
for i,x in enumerate([340,400,460]):
    d.line([(x,450+i*25),(x+60,500+i*25)],fill=(230,57,70),width=18)
# tally marks badge
d.ellipse([640,170,880,410],fill=W)
for x in [700,735,770,805]:
    d.line([(x,230),(x,350)],fill=(230,57,70),width=16)
d.line([(680,330),(830,250)],fill=(40,40,50),width=16)
img.save("AppIcon-1024.png")
print(img.mode,img.size)
