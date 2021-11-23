#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include <string.h>

#include <libusb.h>
#define XVCPICO_VID       0x2E8A
#define XVCPICO_PID       0x0A
#define XVCPICO_INTF      2
#define XVCPICO_READ_EP   0x84
#define XVCPICO_WRITE_EP  0x03
libusb_context *usb_ctx;
libusb_device_handle *dev_handle;

union u_data_t {
  unsigned char c[8];
  short s[4];
  int i[2];
  long long l;
};

union u_send_data_t {
  unsigned char c[1024];
  short s[512];
  int i[128];
  long long l[64];
};

struct send_com_t {
  unsigned char com[4];
  int address;
};

struct send_data_t {
  unsigned char com[4];
  int address;
  union u_send_data_t data;
};

int device_init()
{
  int ret;

  if (libusb_init(&usb_ctx) < 0) {
    printf("[ERROR] libusb init failed!\n");
    return -1;
  }
  dev_handle = libusb_open_device_with_vid_pid(usb_ctx, XVCPICO_VID, XVCPICO_PID);
  if (!dev_handle) {
    printf("[ERROR] failed to open usb device!\n");
    libusb_exit(usb_ctx);
    return -1;
  }
  ret = libusb_claim_interface(dev_handle, XVCPICO_INTF);
  if (ret) {
    printf("[!] libusb error while claiming XVCPICO interface\n");
    libusb_close(dev_handle);
    libusb_exit(usb_ctx);
    return -1;
  }

  return 0; // success
}

void device_close()
{
  if (dev_handle)
    libusb_close(dev_handle);
  if (usb_ctx)
    libusb_exit(usb_ctx);
}

int read_dev(int size, int raddress, unsigned char receive_data[]) {
  int r;
  int actual_length = 0;
  int total_length = 0;

  struct send_com_t send_data;

  send_data.com[0] = 0;
  send_data.com[1] = size%256;
  send_data.com[2] = size/256;
  send_data.address = raddress;

  r = libusb_bulk_transfer(dev_handle, XVCPICO_WRITE_EP, &send_data.com[0], 8, &actual_length, 1000);
  if ( r != 0 ){
    device_close();
    return -1;
  }
  for(int i=0; i < (size+8+63)/64; i++){
    do {
      r = libusb_bulk_transfer(dev_handle, XVCPICO_READ_EP, &receive_data[i*64], 64, &actual_length, 2000);
      if (r < 0) {
        device_close();
        return -1;
      }
    } while (actual_length == 0);
    total_length += actual_length;
    //printf("i %d, t %d\n", i, total_length);
  }
  return total_length;
}

int write_dev(int size, int waddress, struct send_data_t send_data) {
  int r;
  int actual_length = 0;

  send_data.com[0] = 1;
  send_data.com[1] = size%256;
  send_data.com[2] = size/256;
  send_data.address = waddress;

  int ds;
  if(size>=8)     ds = size+8;
  else if(size>4) ds = 8;
  else            ds = size;
  
  int ts;
  if(ds <= 56){
    ts = ds;
    ds = 0;
  }else{
    ts = 56;
    ds -= 56;
  }
    
  r = libusb_bulk_transfer(dev_handle, XVCPICO_WRITE_EP, &send_data.com[0], ts+8 , &actual_length, 1000);// size==6,7 -> 16
  if ( r != 0 ){
    device_close();
    return -1;
  }

  int send_index = 56;

  while(ds != 0){
    if(ds <= 64){
      ts = ds;
      ds = 0;
    }else{
      ts = 64;
      ds -= 64;
    }
    r = libusb_bulk_transfer(dev_handle, XVCPICO_WRITE_EP, &send_data.data.c[send_index], ts , &actual_length, 1000);
    if ( r != 0 ){
      device_close();
      return -1;
    }
    send_index += 64;
  }

  return actual_length;
}

int main() {
  struct send_data_t send_data;
  unsigned char receive_data[1024] = {0};
  unsigned char     send_str[64] = {0};
  int data_len;

  // Init
  if (device_init() != 0) {
    return -1;
  }

  int actual_length;
  int raddress;

  srand((unsigned) time(NULL));
  union u_data_t buf[128];
  struct timeval time1;
  struct timeval time2;
  float write_time;
  float read_time;

  for(int i = 0; i < 128; i++){
    for(int j = 0; j < 4; j++){
      buf[i].s[j] = rand() & 0xffff;
      send_data.data.s[i*4+j] = buf[i].s[j];
    }
  }

  printf("Send data:\n");
  for(int i = 0; i < 5; i++){
    printf("%d, %llx\n", i, buf[i].l);
  }

  int waddress = 0xc0000000;
  gettimeofday(&time1, NULL);
  actual_length = write_dev(1024-8, waddress, send_data);
  //if(actual_length < 0) return -1;
  
  /*for(int i = 0; i < 32; i++){
    send_data.data.l[0] = buf[i*4].l;
    send_data.data.l[1] = buf[i*4+1].l;
    send_data.data.l[2] = buf[i*4+2].l;
    send_data.data.l[3] = buf[i*4+3].l;
    actual_length = write_dev(24, waddress, send_data);
    if(actual_length < 0) return -1;
    waddress += 32;
  }/**/
  /*for(int i = 0; i < 128; i++){
    for(int j = 0; j < 2; j++){
      send_data.data.l[0] = buf[i].i[j];
      actual_length = write_dev(4, waddress, send_data);
      if(actual_length < 0) return -1;
      waddress += 4;
    }
  }/**/
  gettimeofday(&time2, NULL);
  write_time = (time2.tv_sec - time1.tv_sec) * 1000 +  (float)(time2.tv_usec - time1.tv_usec) / 1000;
  printf("Send data: %5.2f ms\n", write_time);

  printf("Recieve data\n");
  raddress = 0xc0000000;
  for(int i = 0; i < 4; i++){
    for(int ii = 0; ii < 1; ii++){
      actual_length = read_dev(6, raddress, receive_data);
      printf("length %d\n", actual_length);
      if(actual_length < 0) return -1;
      printf("%d, ", i);
      for ( int j = 0; j < actual_length; j++ )
        printf("%02X ", receive_data[actual_length-j-1]);
      printf("\n");
      for ( int j = 0; j < actual_length; j++ )
        if(buf[i].c[ii*8+j] != receive_data[j])
          printf("error: %d, %d\n", i, j);
      raddress += 8;
    }
  }

  gettimeofday(&time1, NULL);
  raddress = 0xc0000000;
  actual_length = read_dev(1024-8, raddress, receive_data);
  if(actual_length < 0) return -1;
  for ( int j = 0; j < actual_length; j++ )
    if(buf[j/8].c[j%8] != receive_data[j])
      printf("error: %d, %d\n", 0, j);
  //printf("len %d\n", actual_length);
  /*for(int i = 0; i < 2; i++){
      actual_length = read_dev(512-8, raddress, receive_data);
      if(actual_length < 0) return -1;
      for ( int j = 0; j < actual_length; j++ )
        if(buf[i*64+j/8].c[j%8] != receive_data[j])
          printf("error: %d, %d\n", i, j);
      raddress += 512;
    }
  /*for(int i = 0; i < 128; i++){
    for(int ii = 0; ii < 1; ii++){
      actual_length = read_dev(6, raddress, receive_data);
      if(actual_length < 0) return -1;
      for ( int j = 0; j < actual_length; j++ )
        if(buf[i].c[ii*1+j] != receive_data[j])
          printf("error: %d, %d\n", i, j);
      raddress += 8;
    }
  }/**/
  gettimeofday(&time2, NULL);
  read_time = (time2.tv_sec - time1.tv_sec) * 1000 +  (float)(time2.tv_usec - time1.tv_usec) / 1000;
  printf("Recieve data: %5.2f ms\n", read_time);

  sprintf((char*)send_str, "Send data: %5.2f ms\r\n", write_time);
  data_len = strlen((char*)send_str) + 1;
  waddress = 0x40600004;
  raddress = 0x40600008;
  for(int i = 0; i < data_len; i++){
  
    send_data.data.c[0] = send_str[i];
    send_data.data.c[1] = 0;
    send_data.data.c[2] = 0;
    send_data.data.c[3] = 0;
    do{
      actual_length = read_dev(1, raddress, receive_data);
    }while((receive_data[0]&0x4) != 4);
    actual_length = write_dev(4, waddress, send_data);
  }
  sprintf((char*)send_str, "Recieve data: %5.2f ms\r\n", read_time);
  data_len = strlen((char*)send_str) + 1;
  waddress = 0x40600004;
  raddress = 0x40600008;
  for(int i = 0; i < data_len; i++){
  
    send_data.data.c[0] = send_str[i];
    send_data.data.c[1] = 0;
    send_data.data.c[2] = 0;
    send_data.data.c[3] = 0;
    do{
      actual_length = read_dev(1, raddress, receive_data);
    }while((receive_data[0]&0x4) != 4);
    actual_length = write_dev(4, waddress, send_data);
  }

  raddress = 0x40600000;

  actual_length = read_dev(1, 0x40600008, receive_data);
  while((receive_data[0]&0x1) == 1){
    actual_length = read_dev(1, raddress, receive_data);
    if(receive_data[0] == 0x0d) printf("\n");
    else                        printf("%c", receive_data[0]);
    actual_length = read_dev(1, 0x40600008, receive_data);
  }
  printf("\n");
  
  device_close();
  return 0;
}
