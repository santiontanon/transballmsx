/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package mapconverter;

import java.util.ArrayList;
import java.util.List;
import org.jdom.Document;
import org.jdom.Element;
import org.jdom.input.SAXBuilder;

/**
 *
 * @author santi
 */
public class TMX2Assembler {
    public static void main(String args[]) throws Exception {
        String inputMap = "graphics/map15.tmx";
//        String inputMap = "graphics/titlescreen-es.tmx";
        
        int [][]maparray = importTMX(inputMap);
        
        countNumberOfAnimations(maparray);
        //convertToAssemblerPlain(maparray);
//        convertToAssemblerRunLengthEncodingPerLine(maparray, 255);
        convertToAssemblerRunLengthEncoding(maparray, 255);
    }


    public static void countNumberOfAnimations(int [][]maparray) {
        List<Integer> animationTiles = new ArrayList<>();
        animationTiles.add(130);
        animationTiles.add(131);
        animationTiles.add(136);
        animationTiles.add(137);
        animationTiles.add(134);
        animationTiles.add(248);
        animationTiles.add(249);
        animationTiles.add(252);
        animationTiles.add(253);
        
        int width = maparray[0].length;
        int height = maparray.length;
        int nanimations = 0;
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                if (animationTiles.contains(maparray[i][j])) nanimations++;
            }
        }
        System.out.println("; number of animation tiles: " + nanimations);
    }
    
    
    public static void convertToAssemblerPlain(int [][]maparray) {
        int width = maparray[0].length;
        int height = maparray.length;
        
        for(int i = 0;i<height;i++) {
            System.out.print("    db ");
            for(int j = 0;j<width;j++) {
                System.out.print(maparray[i][j]);
                if (j<width-1) System.out.print(",");
            }
            System.out.println("");
        }
        System.out.println(";; Regular encoding (size: " + width + "*" + height + " = " + width*height + ")");
    }
    

    public static void convertToAssemblerRunLengthEncodingPerLine(int [][]maparray, int meta) {
        int width = maparray[0].length;
        int height = maparray.length;
        int size = 0;
        
        for(int i = 0;i<height;i++) {
            System.out.print("    db ");
            List<Integer> encoding = new ArrayList<>();            
            for(int j = 0;j<width;) {
                int last = maparray[i][j];
                int count = 0;
                do{
                    count++;
                    j++;
                }while(j<width && maparray[i][j]==last);
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
            for(int j = 0;j<encoding.size();j++) {
                System.out.print(encoding.get(j));
                if (j<encoding.size()-1) System.out.print(",");
            }
            System.out.println("");
            size+=encoding.size();
        }
        System.out.println(";; Run-length encoding per line (size: "+size+")");
    }

    

    public static void convertToAssemblerRunLengthEncoding(int [][]maparray, int meta) {
        int width = maparray[0].length;
        int height = maparray.length;
        int size = 0;
        
        System.out.println(";; map is " + width + " * " + height);
        int i = 0, j = 0;
        for(;i<height;) {
            System.out.print("    db ");
            List<Integer> encoding = new ArrayList<>();       
            int last_i = i;
            for(;j<width && i==last_i;) {
                int last = maparray[i][j];
                int count = 0;
                do {
                    do{
                        count++;
                        j++;
                    }while(j<width && maparray[i][j]==last && count<255);
                    if (j>=width) {
                        j = 0;
                        i++;
                    }
                }while(i<height && maparray[i][j]==last && count<255);
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
            for(int k = 0;k<encoding.size();k++) {
                System.out.print(encoding.get(k));
                if (k<encoding.size()-1) System.out.print(",");
            }
            System.out.println("");
            size+=encoding.size();
        }
        System.out.println(";; Run-length encoding (size: "+size+")");
    }
    
    
    
    public static int [][]importTMX(String fileName) throws Exception {
        Element e = new SAXBuilder().build(fileName).getRootElement();
        
        int width = Integer.parseInt(e.getAttributeValue("width"));
        int height = Integer.parseInt(e.getAttributeValue("height"));;
        int map[][] = new int[height][width];
        
        int i = 0, j = 0;
        Element layer_e = e.getChild("layer");
        for(Object o2:layer_e.getChild("data").getChildren("tile")) {
            Element tile_e = (Element)o2;
            int id = Integer.parseInt(tile_e.getAttributeValue("gid"))-1;
            if (id<0) id = 0;
            map[i][j] = id;
            j++;
            if (j>=width) {
                j = 0;
                i++;
            }
        }
        return map;
    }
}
