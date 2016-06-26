/*
 * Santiago Ontanon Villar.
 */
package PNGtoMSXGraphicsConverter;

import java.awt.GraphicsConfiguration;
import java.awt.GraphicsEnvironment;
import java.awt.Transparency;
import java.awt.image.BufferedImage;
import java.util.Arrays;

/**
 *
 * @author santi
 */
public class EightBitConverter {

    int palette[][];
    int maxColorsPerAttributeBlock = 2;
    int attributeBlockWidth = 8;
    int attributeBlockHeight = 8;
    
    
    public static EightBitConverter getMSXConverter() {
        int MSX1Palette[][] = {{0,0,0},
                                {0,0,0},
                                {43,221,81},
                                {100,255,118},
                                {81,81,255},
                                {118,118,255},
                                {221,81,81},
                                {81,255,255},
                                {255,81,81},
                                {255,118,118},
                                {255,221,81},
                                {255,255,160},
                                {43,187,43},
                                {221,81,187},
                                {221,221,221},
                                {255,255,255}};        
        return new EightBitConverter(MSX1Palette, 2, 8, 1);
    }    
    
    public static EightBitConverter getMSXConverterCharacterBlobcks() {
        EightBitConverter c = getMSXConverter();
        c.attributeBlockHeight = 8;
        return c;
    }


    public EightBitConverter(int a_palette[][], int cpab, int abw, int abh) {
        palette = a_palette;
        maxColorsPerAttributeBlock = cpab;
        attributeBlockWidth = abw;
        attributeBlockHeight = abh;
    }


    public BufferedImage convertSpriteIgnoringAttributeBlocks(BufferedImage i) {
        for(int y = 0;y<i.getHeight();y++) {
            for(int x = 0;x<i.getWidth();x++) {
                int color = i.getRGB(x, y);
                int r = color & 0x0000ff;
                int g = (color & 0x00ff00)>>8;
                int b = (color & 0xff0000)>>16;
                int a = (color & 0xff000000)>>24;
                int bestc = -1;
                int besterror = -1;

//                System.out.println(x + "," + y + " -> (" + r + "," + g + "," + b + ")");
                for(int c = 0;c<palette.length;c++) {
                    int e = (int)Math.sqrt((palette[c][0]-r)*(palette[c][0]-r) +
                                           (palette[c][1]-g)*(palette[c][1]-g) +
                                           (palette[c][2]-b)*(palette[c][2]-b));
                    if (besterror==-1 || e<besterror) {
                        bestc = c;
                        besterror = e;
                    }
                }
                i.setRGB(x, y, palette[bestc][0] + (palette[bestc][1]<<8) + (palette[bestc][2]<<16) + (a<<24));
            }
        }
        return i;
    }

    
    public BufferedImage convertSpriteToNColors(BufferedImage i, int nColors) {
//        System.out.println("ConvertSprite:");
        int chosenColors[] = new int[nColors];
        int colors[] = new int[nColors];
        double bestError = -1;
        for(int c = 0;c<nColors;c++) colors[c] = c;
        do{
            double error = conversionError(i, colors, 0, 0, i.getWidth(), i.getHeight());
            if (bestError==-1 || error<bestError) {
                for(int c = 0;c<nColors;c++) chosenColors[c] = colors[c];
                bestError = error;
            }
        }while(nextColors(colors));
//                System.out.println("  chosen " + Arrays.toString(chosenColors) + " -> " + bestError);
        convertToGivenColors(i, i, chosenColors, 0, 0, i.getWidth(), i.getHeight());
        return i;
    }
    

    public BufferedImage convertSprite(BufferedImage sp) {
//        System.out.println("ConvertSprite:");
        GraphicsConfiguration gc = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();
        BufferedImage i = gc.createCompatibleImage(sp.getWidth(), sp.getHeight(), Transparency.BITMASK);
        for(int by = 0;by<sp.getHeight();by+=attributeBlockHeight) {
            for(int bx = 0;bx<sp.getWidth();bx+=attributeBlockWidth) {
                int chosenColors[] = new int[maxColorsPerAttributeBlock];
                int colors[] = new int[maxColorsPerAttributeBlock];
                double bestError = -1;
                for(int c = 0;c<maxColorsPerAttributeBlock;c++) colors[c] = c;
                do{
                    double error = conversionError(sp, colors, bx, by, attributeBlockWidth, attributeBlockHeight);
                    if (bestError==-1 || error<bestError) {
                        for(int c = 0;c<maxColorsPerAttributeBlock;c++) chosenColors[c] = colors[c];
                        bestError = error;
                    }
                }while(nextColors(colors));
//                System.out.println("  chosen " + Arrays.toString(chosenColors) + " -> " + bestError);
                convertToGivenColors(i, sp, chosenColors, bx, by, attributeBlockWidth, attributeBlockHeight);
            }
        }
        return i;
    }


    boolean nextColors(int colors[]) {
        int c = colors.length-1;
        do {
            int tmp = (colors.length - 1) - c; 
            
            colors[c]++;
            // make sure that they are in ascending order:
            for(int c1 = c+1;c1<colors.length;c1++) {
                colors[c1] = colors[c1-1]+1;
            }
            if (colors[c]>=palette.length-tmp) {
                colors[c] = 0;
                c--;
                if (c<0) return false;
            } else {
//                System.out.println(Arrays.toString(colors));
                return true;
            }
        }while(true);        
    }


    public void convertToGivenColors(BufferedImage i, BufferedImage sp, int colors[], int x0, int y0, int w, int h) {
        for(int y = y0;y<y0+h;y++) {
            for(int x = x0;x<x0+w;x++) {
                int color = sp.getRGB(x, y);
                int a = (color & 0xff000000)>>24;
                int rgb[] = {color & 0x0000ff, (color & 0x00ff00)>>8, (color & 0xff0000)>>16};
                int bestc = -1;
                double besterror = -1;

//                System.out.println(x + "," + y + " -> (" + r + "," + g + "," + b + ")");
                for(int idx = 0;idx<colors.length;idx++) {
                    int c = colors[idx];
//                    double e = euclideanError(palette[c],rgb);
                    double e = colorError(palette[c],rgb);
                    if (besterror==-1 || e<besterror) {
                        bestc = c;
                        besterror = e;
                    }
                }
                i.setRGB(x, y, palette[bestc][0] + (palette[bestc][1]<<8) + (palette[bestc][2]<<16) + (a<<24));
            }
        }
    }


    double euclideanError(int c1[], int c2[]) {
        double e1 = Math.sqrt((c1[0]-c2[0])*(c1[0]-c2[1]) +
                              (c1[1]-c2[1])*(c1[1]-c2[1]) +
                              (c1[2]-c2[2])*(c1[2]-c2[2]));
        return e1;
    }


    double colorError(int c1[], int c2[]) {
        double norm1 = Math.sqrt(c1[0]*c1[0] + c1[1]*c1[1] + c1[2]*c1[2]);
        double norm2 = Math.sqrt(c2[0]*c2[0] + c2[1]*c2[1] + c2[2]*c2[2]);
        double dotProduct = c1[0]*c2[0] + c1[1]*c2[1] + c1[2]*c2[2];

        if (norm1==0 && norm2!=0) return 4; // max error
        if (norm1!=0 && norm2==0) return 4; // max error
        if (norm1==0 && norm2==0) return 0;
        
        double cosine = dotProduct/(norm1*norm2);

        double errorAngle = 1 - cosine*cosine;
        double errorMagnitude = Math.abs(norm1-norm2)/Math.sqrt(255*255 + 255*255 + 255*255);
        double e = errorAngle + errorMagnitude;
/*        
        System.out.println("c1: " + Arrays.toString(c1));
        System.out.println("c2: " + Arrays.toString(c2));
        System.out.println("   e_a = " + errorAngle);
        System.out.println("   e_m = " + errorMagnitude);
  */      
//        System.out.println(e);

        return e;
    }
  

    double conversionError(BufferedImage sp, int chosenColors[], int x0, int y0, int w, int h) {
        double error = 0;
        for(int y = y0;y<y0+h;y++) {
            for(int x = x0;x<x0+w;x++) {
                int color = sp.getRGB(x, y);
                int rgb[] = {color & 0x0000ff, (color & 0x00ff00)>>8, (color & 0xff0000)>>16};
                double e = -1;
                for(int c:chosenColors) {
//                    double e1 = euclideanError(palette[c], rgb);
                    double e1 = colorError(palette[c], rgb);
                    if (e==-1 || e1<e) e = e1;
                }
                error += e;
            }
        }
        return error;
    }

}
