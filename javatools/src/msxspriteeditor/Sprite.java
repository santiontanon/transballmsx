/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package msxspriteeditor;

/**
 *
 * @author santi
 */
public class Sprite {
    String id = null;
    public int sprite[][];    
    
    public Sprite(int w, int h, String a_id) {
        sprite = new int[w][h];
        id = a_id;
    }
    
    
    public void overwrite(int sp[][]) {
        for(int j = 0;j<sp.length;j++) {
            for(int i = 0;i<sp[0].length;i++) {
                sprite[j][i] = sp[j][i];
            }
        }
    }
    
    public String toString() {
        return id;
    }
    
    public String generateAssemblerString(String indentation) {
        int masks[] = {128,64,32,16,8,4,2,1};
        int width = sprite.length;
        int height = sprite[0].length;
        String out = indentation + "db ";
        for(int j = 0;j<width;j+=8) {
            for(int i = 0;i<height;i++) {
                int n = 0;
                for(int k = 0;k<8;k++) {
                    n+=(sprite[j+k][i])*masks[k];
                }
                String hex = hexString8bit(n);
                out += "#" + hex;
                if (i+1<height) out +=",";
            }
            if (j+8<width) out +="\n"+indentation+"db ";
        }
        return out;
    }
    
    
    public String hexString8bit(int n) {
        String c[]={"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"};
        int low = n%16;
        int high = (n/16)%16;
        return c[high] + c[low];
    }    
}
