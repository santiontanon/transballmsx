/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package mapconverter;

import static mapconverter.TMX2Assembler.convertToAssemblerRunLengthEncoding;
import static mapconverter.TMX2Assembler.countNumberOfAnimations;
import static mapconverter.TMX2Assembler.importTMX;

/**
 *
 * @author santi
 */
public class GenerateMapsFile {
    public static void main(String args[]) throws Exception {
        String inputMaps[] = {"graphics/map1.tmx",
                              "graphics/map2.tmx",
                              "graphics/map3.tmx",
                              "graphics/map4.tmx",
                              "graphics/map5.tmx",
                              "graphics/map6.tmx",
                              "graphics/map7.tmx",
                              "graphics/map8.tmx",
                              "graphics/map9.tmx",
                              "graphics/map10.tmx",
                              "graphics/map11.tmx",
                              "graphics/map12.tmx",
                              "graphics/map13.tmx",
                              "graphics/map14.tmx",
                              "graphics/map15.tmx",
                              "graphics/map16.tmx",};
        int startingFuel[] = {10,
                              10,
                              10,
                              10,
                              10,
                              10,
                              10,
                              10,
                              3,
                              10,
                              10,
                              10,
                              10,
                              10,
                              10,
                              10};
        int emptyTopRows[] = {4,
                              4,
                              4,
                              8,
                              8,
                              6,
                              4,
                              4,
                              8,
                              8,
                              8,
                              7,
                              8,
                              8,
                              8,
                              8};
        
        for(int i = 0;i<16;i++) {
            int fuel = startingFuel[i];
            
            int [][]maparray = importTMX(inputMaps[i]);
            maparray = insertEmptyRows(emptyTopRows[i], maparray);
            
            System.out.println("map" + (i+1) + ":");
            System.out.println("    db " + startingFuel[i] + ",FUEL_UNIT");
            int width = maparray[0].length;
            int height = maparray.length;
            System.out.println("    db " + height + "," + width);
            
            countNumberOfAnimations(maparray);
            convertToAssemblerRunLengthEncoding(maparray, 255);        

            System.out.println("");
        }
        
    }

    
    private static int[][] insertEmptyRows(int emptyTopRows, int [][]map) {
        int width = map[0].length;
        int height = map.length;
        int [][]newMap = new int[map.length+emptyTopRows][map[0].length];
        
        for(int i = 0;i<emptyTopRows;i++) {
            for(int j = 0;j<width;j++) {
                newMap[i][j] = 0;
            }
        }
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                newMap[i+emptyTopRows][j] = map[i][j];
            }
        }
        return newMap;
    }
}
