/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package msxspriteeditor.shipsprites;

import java.util.ArrayList;
import java.util.List;
import msxspriteeditor.MSXSpriteEditor;
import msxspriteeditor.Sprite;

/**
 *
 * @author santi
 */
public class SpritesWithRLE {
    public static void main(String args[]) throws Exception {
        List<Sprite> shipSprites = MSXSpriteEditor.importHex(SpriteMirroring.shipSpritesString);
        List<Sprite> thrusterSprites = MSXSpriteEditor.importHex(SpriteMirroring.thrusterSpritesString);
        
        shipSprites = SpriteMirroring.generate32FramesFrom5(shipSprites);
        thrusterSprites = SpriteMirroring.generate32FramesFrom5(thrusterSprites);
        
        // generate a string of bytes with the info that needs to be saved:
        List<Integer> bytesForShipSprites1 = new ArrayList<>();
        List<Integer> bytesForShipSprites2 = new ArrayList<>();
        List<Integer> bytesForThrusterSprites1 = new ArrayList<>();
        List<Integer> bytesForThrusterSprites2 = new ArrayList<>();
        
//        for(int i = 0;i<32;i++) addSpriteBytes(shipSprites.get(i), bytesForShipSprites);
//        for(int i = 0;i<32;i++) addSpriteBytes(thrusterSprites.get(i), bytesForThrusterSprites);

        for(int i = 0;i<=8;i++) addSpriteBytes(shipSprites.get(i), bytesForShipSprites1);
        for(int i = 17;i<=24;i++) addSpriteBytes(shipSprites.get(i), bytesForShipSprites2);

        for(int i = 0;i<=8;i++) addSpriteBytes(thrusterSprites.get(i), bytesForThrusterSprites1);
        for(int i = 17;i<=24;i++) addSpriteBytes(thrusterSprites.get(i), bytesForThrusterSprites2);

        System.out.println(";; original data size: " + bytesForShipSprites1.size());
        convertToAssemblerRunLengthEncoding(bytesForShipSprites1,255);
        System.out.println(";; original data size: " + bytesForShipSprites2.size());
        convertToAssemblerRunLengthEncoding(bytesForShipSprites2,255);
        
        System.out.println(";; original data size: " + bytesForThrusterSprites1.size());
        convertToAssemblerRunLengthEncoding(bytesForThrusterSprites1,255);
        System.out.println(";; original data size: " + bytesForThrusterSprites2.size());
        convertToAssemblerRunLengthEncoding(bytesForThrusterSprites2,255);
    }

    
    private static void addSpriteBytes(Sprite sp, List<Integer> bytesForShipSprites) {
        String indentation = "    ";
        int masks[] = {128,64,32,16,8,4,2,1};
        int width = sp.sprite.length;
        int height = sp.sprite[0].length;
        String out = indentation + "db ";
        for(int j = 0;j<width;j+=8) {
            for(int i = 0;i<height;i++) {
                int n = 0;
                for(int k = 0;k<8;k++) {
                    n+=(sp.sprite[j+k][i])*masks[k];
                }
                bytesForShipSprites.add(n);
            }
        }
    }
    
    
    public static void convertToAssemblerRunLengthEncoding(List<Integer> data, int meta) {
        int width = data.size();
        int size = 0;
        int maxLineSize = 16;
        
//        System.out.println("    ;; map is " + width + " * " + height);
        int i = 0, j = 0;
        List<Integer> encoding = new ArrayList<>();       
        int last_i = i;
        for(;j<width && i==last_i;) {
            int last = data.get(j);
            int count = 0;
            do{
                count++;
                j++;
            }while(j<width && data.get(j)==last && count<255);
            if (count==1 && last!=meta) {
                encoding.add(last);
            } else if (count==2 && last!=meta) {
                encoding.add(last);
                encoding.add(last);
            } else {
                encoding.add(meta);
                encoding.add(last);
                encoding.add(count);
            }
        }

        for(int k = 0;k<encoding.size();) {        
            System.out.print("    db ");
            int bytesInCurrentLine = 0;
            for(;k<encoding.size() && bytesInCurrentLine<maxLineSize;k++) {
                System.out.print(encoding.get(k));
                bytesInCurrentLine++;
                if (k<encoding.size()-1 && bytesInCurrentLine<maxLineSize) System.out.print(",");
            }
            System.out.println("");
        }
        size+=encoding.size();
        System.out.println("    ;; Run-length encoding (size: "+size+")");
    }    
}
