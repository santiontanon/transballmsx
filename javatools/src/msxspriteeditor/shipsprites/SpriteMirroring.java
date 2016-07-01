/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package msxspriteeditor.shipsprites;

import java.util.List;
import msxspriteeditor.MSXSpriteEditor;
import msxspriteeditor.Sprite;

/**
 *
 * @author santi
 * 
 * This file takes a set of sprites representing rotations of 0, 11.25, 22.5, 33.75 and 45 degrees,
 * and generates the rest of the angles.
 */
public class SpriteMirroring {
    public static String shipSpritesString = 
"        ; 0\n" +
"        db #00,#00,#01,#01,#03,#02,#06,#06,#0f,#0f,#1f,#1f,#3f,#3c,#03,#00\n" +
"        db #00,#00,#80,#80,#c0,#40,#60,#60,#f0,#f0,#f8,#f8,#fc,#3c,#c0,#00\n" +
"        ; 11.25\n" +
"        db #00,#00,#00,#01,#03,#07,#06,#0e,#1f,#1f,#3f,#7f,#03,#0c,#03,#00\n" +
"        db #00,#00,#c0,#c0,#e0,#20,#60,#60,#e0,#f0,#f0,#f0,#f0,#f8,#38,#00\n" +
"        ; 22.5\n" +
"        db #00,#00,#00,#00,#03,#07,#0e,#1e,#7f,#ff,#3f,#07,#19,#06,#00,#00\n" +
"        db #00,#00,#60,#e0,#e0,#20,#20,#60,#f0,#f0,#f0,#f0,#f0,#f0,#30,#00\n" +
"        ; 33.75\n" +
"        db #00,#00,#00,#00,#01,#07,#1f,#7f,#7f,#3f,#0f,#13,#0d,#02,#00,#00\n" +
"        db #00,#00,#30,#70,#f0,#90,#10,#30,#f0,#e0,#e0,#e0,#e0,#e0,#60,#00\n" +
"        ; 45\n" +
"        db #00,#00,#00,#00,#00,#0f,#7f,#7f,#3f,#0f,#17,#0b,#05,#01,#00,#00\n" +
"        db #00,#00,#00,#18,#f8,#90,#10,#30,#e0,#e0,#e0,#e0,#c0,#c0,#c0,#00";
    
    public static String thrusterSpritesString =
"    ; 0\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#03,#01\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#c0,#80\n" +
"    ; 11.25\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#0c,#07,#02\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00\n" +
"    ; 22.5\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#18,#0e,#04,#00\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00\n" +
"    ; 33.75\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#10,#1c,#0e,#00,#00\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00\n" +
"    ; 45\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#10,#18,#0c,#00,#00,#00\n" +
"    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00";            



    public static void main(String args[]) throws Exception {
        List<Sprite> shipSprites = MSXSpriteEditor.importHex(shipSpritesString);
        List<Sprite> thrusterSprites = MSXSpriteEditor.importHex(thrusterSpritesString);
        
        shipSprites = generate32FramesFrom5(shipSprites);
        thrusterSprites = generate32FramesFrom5(thrusterSprites);
        
        String indent = "    ";
        System.out.println("shipvpanther:");
        for(Sprite sp:shipSprites) {
            String header = indent + "; " + sp.id + "\n";
            String sp_text = sp.generateAssemblerString(indent);
            System.out.println(header + sp_text);
        }
        System.out.println("shipvpanther_thruster:");
        for(Sprite sp:thrusterSprites) {
            String header = indent + "; " + sp.id + "\n";
            String sp_text = sp.generateAssemblerString(indent);
            System.out.println(header + sp_text);
        }
        
    }


    
    public static List<Sprite> generate32FramesFrom5(List<Sprite> sprites) throws Exception {
        
        // 5
        sprites.add(secondDiagonalFlip(sprites.get(3),"56.25"));
        sprites.add(secondDiagonalFlip(sprites.get(2),"67.5"));
        sprites.add(secondDiagonalFlip(sprites.get(1),"78.75"));

        // 8
        sprites.add(secondDiagonalFlip(sprites.get(0),"90"));
        
        sprites.add(flipSprite(sprites.get(7),"101.25", false, true));
        sprites.add(flipSprite(sprites.get(6),"112.5", false, true));
        sprites.add(flipSprite(sprites.get(5),"123.75", false, true));
        sprites.add(flipSprite(sprites.get(4),"135", false, true));
        sprites.add(flipSprite(sprites.get(3),"146.25", false, true));
        sprites.add(flipSprite(sprites.get(2),"157.5", false, true));
        sprites.add(flipSprite(sprites.get(1),"168.75", false, true));
        
        // 16
        sprites.add(flipSprite(sprites.get(0),"180", false, true));
        
        sprites.add(flipSprite(sprites.get(15),"191.25", true, false));
        sprites.add(flipSprite(sprites.get(14),"202.5", true, false));
        sprites.add(flipSprite(sprites.get(13),"213.75", true, false));
        sprites.add(flipSprite(sprites.get(12),"225", true, false));
        sprites.add(flipSprite(sprites.get(11),"236.25", true, false));
        sprites.add(flipSprite(sprites.get(10),"247.5", true, false));
        sprites.add(flipSprite(sprites.get(9),"258.75", true, false));
        sprites.add(flipSprite(sprites.get(8),"270", true, false));
        sprites.add(flipSprite(sprites.get(7),"281.25", true, false));
        sprites.add(flipSprite(sprites.get(6),"292.5", true, false));
        sprites.add(flipSprite(sprites.get(5),"303.75", true, false));
        sprites.add(flipSprite(sprites.get(4),"315", true, false));
        sprites.add(flipSprite(sprites.get(3),"326.25", true, false));
        sprites.add(flipSprite(sprites.get(2),"337.5", true, false));
        sprites.add(flipSprite(sprites.get(1),"348.75", true, false));

        return sprites;
                
    }
    
    
    public static Sprite flipSprite(Sprite sprite, String name,  boolean flipX, boolean flipY) {
        Sprite newSprite = new Sprite(16,16,name);
        
        for(int i = 0;i<16;i++) {
            int i2 = (flipX ? 15-i:i);
            for(int j = 0;j<16;j++) {
                int j2 = (flipY ? 15-j:j);
                newSprite.sprite[i2][j2] = sprite.sprite[i][j];
            }
        }
        
        return newSprite;
    }
    
    
    public static Sprite diagonalFlip(Sprite sprite, String name) {
        Sprite newSprite = new Sprite(16,16,name);
        
        for(int i = 0;i<16;i++) {
            for(int j = 0;j<16;j++) {
                newSprite.sprite[j][i] = sprite.sprite[i][j];
            }
        }
        
        return newSprite;
    }    


    public static Sprite secondDiagonalFlip(Sprite sprite, String name) {
        Sprite newSprite = new Sprite(16,16,name);
        
        for(int i = 0;i<16;i++) {
            for(int j = 0;j<16;j++) {
                newSprite.sprite[15-j][15-i] = sprite.sprite[i][j];
            }
        }
        
        return newSprite;
    }    

}
