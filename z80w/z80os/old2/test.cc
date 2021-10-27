#include <iostream.h>

unsigned short chksum(unsigned char *sdata, int len)
{
  unsigned short acc;
  unsigned int data=0;
  
  for(acc = 0; len > 1; len -= 2) {
    acc += (sdata[1]|(sdata[0]<<8));
    data += (sdata[1]|(sdata[0]<<8));
    cout<<acc<<"@"<<(sdata[1]|(sdata[0]<<8))<<endl;
    if(acc < (sdata[1]|(sdata[0]<<8))) {
      /* Overflow, so we add the carry to acc (i.e., increase by
         one). */
      acc++;
    }
    sdata+=2;
  }
  
  cout<<endl<<data<<"=~"<<~data<<endl;
  /* add up any odd byte */
/*  if(len == 1) {
    acc += htons(((u16_t)(*(u8_t *)sdata)) << 8);
    if(acc < htons(((u16_t)(*(u8_t *)sdata)) << 8)) {
      ++acc;
    }
  }*/

  return(acc);
}

int main(void){
 hex(cout);
 unsigned short ret=0;
 unsigned char table[]={
0x45,0x00,0x00,0x3c,0x4c,0x13,0x00,0x00,0x40,0x01,0x00,0x00,0x6f,0x70,0x71,0xd9,0x6f,0x70,0x71,0xd8
 };
 
 ret=chksum((unsigned char*)&table,20);
 cout<<ret<<"=~"<<~ret<<endl;
 
 return(0);
}
