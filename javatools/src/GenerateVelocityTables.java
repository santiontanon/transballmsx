/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author santi
 */
public class GenerateVelocityTables {
    public static void main(String args[]) {
        int divisions = 32;
        generateVelocityTable("0.125pixel_velocity",2, divisions);
        generateVelocityTable("0.25pixel_velocity",4, divisions);
        generateVelocityTable("0.5pixel_velocity",8, divisions);
        generateVelocityTable("1pixel_velocity",16, divisions);
        generateVelocityTable("4pixel_velocity",64, divisions);
    }
    
    public static void generateVelocityTable(String name, double speed, int divisions) {
        double angle = 180.0;
        double inc = 360.0/divisions;
        
        System.out.println("");
        System.out.println(";-----------------------------------------------");
        System.out.println("; velocities of objects ("+speed/16+" pixel per frame)");
        System.out.println("y_" + name + ":");
        System.out.print("    dw ");
        int i = 0;
        for(;i<divisions/4;i++) {
            int value = (int)(Math.round(Math.cos(angle/180*Math.PI)*speed));
            System.out.print(value);
            if (i<(divisions/4)-1) System.out.print(", ");
            angle+=inc;
        }
        System.out.println("");
        System.out.println("x_" + name + ":");
        System.out.print("    dw ");
        for(;i<divisions/2;i++) {
            int value = (int)(Math.round(Math.cos(angle/180*Math.PI)*speed));
            System.out.print(value);
            if (i<(divisions/2)-1) System.out.print(", ");
            angle+=inc;
        }
        System.out.println("");
        System.out.print("    dw ");
        for(;i<divisions;i++) {
            int value = (int)(Math.round(Math.cos(angle/180*Math.PI)*speed));
            System.out.print(value);
            if (i<(divisions)-1) System.out.print(", ");
            angle+=inc;
        }
        System.out.println("");
        System.out.print("    dw ");
        for(i=0;i<divisions/4;i++) {
            int value = (int)(Math.round(Math.cos(angle/180*Math.PI)*speed));
            System.out.print(value);
            if (i<(divisions/4)-1) System.out.print(", ");
            angle+=inc;
        }
        System.out.println("");
    }
}
