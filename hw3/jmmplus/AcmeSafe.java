import java.util.concurrent.atomic.AtomicIntegerArray;

class AcmeSafe implements State {
  private AtomicIntegerArray value;
  private byte maxval;

  public void setvalue(byte[] v){
    value = new AtomicIntegerArray(v.length);
    for (int i = 0; i < v.length; i++) value.set(i, v[i]);
  }

  AcmeSafe(byte[] v) { setvalue(v); maxval = 127; }

  AcmeSafe(byte[] v, byte m) { setvalue(v); maxval = m; }
  public int size(){
    return value.length();
  }

  public byte[] current() {
        byte[] v = new byte[value.length()];
        for (int i = 0; i < v.length; i++)
            v[i] = (byte) value.get(i);
        return v;
   }

 public boolean swap(int i, int j) {
   if (value.get(i) <= 0 || value.get(j) >= maxval) {
     return false;
   }
   value.set(i,value.get(i)-1);
   value.set(j,value.get(j)+1);
   return true;
 }



}
