/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package PNGtoMSXGraphicsConverter;

import java.awt.Graphics2D;
import java.awt.GraphicsConfiguration;
import java.awt.GraphicsEnvironment;
import java.awt.Transparency;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;

/**
 *
 * @author santi
 */
public class Tile2MSXConverter {
    public static void main(String args[]) throws Exception {
        String inputFile = "/Users/santi/Dropbox/Brain/8bit-programming/MSX/tiles-rock-8x8.png";
        String outputFile = "/Users/santi/Dropbox/Brain/8bit-programming/MSX/tiles-rock-8x8-MSX.png";
        EightBitConverter converterMSX = EightBitConverter.getMSXConverter();
        convertImage(inputFile, converterMSX, outputFile);
    }
        
    public static void convertImage(String in, EightBitConverter converter, String out) throws Exception {
        File f = new File(in);
        BufferedImage sourceImage = ImageIO.read(f);
        int w = sourceImage.getWidth();
        int h = sourceImage.getHeight();
        int pw = converter.attributeBlockWidth;
        int ph = converter.attributeBlockHeight;
        GraphicsConfiguration gc = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();
        BufferedImage image = gc.createCompatibleImage(w, h, Transparency.BITMASK);
        Graphics2D g2d = image.createGraphics();
        
        for(int y = 0;y<h;y+=ph) {
            for(int x = 0;x<w;x+=pw) {
                System.out.println(y + ", " + x + " ...");
                
                BufferedImage pattern = gc.createCompatibleImage(pw, ph, Transparency.BITMASK);
                pattern.getGraphics().drawImage(sourceImage, 0,0, pw, ph, x, y, x+pw, y+ph, null);                
                BufferedImage c = converter.convertSprite(pattern);
                g2d.drawImage(c, x, y, null);
            }
        }
        
        File outputfile = new File(out);
        ImageIO.write(image, "png", outputfile);        
    }  

}
