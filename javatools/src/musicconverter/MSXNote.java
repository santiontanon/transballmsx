/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package musicconverter;

/**
 *
 * @author santi
 */
public class MSXNote {
    public static final int SILENCE = -1;
    public static final int GOTO = -2;
    public static final int REPEAT = -3;
    public static final int END_REPEAT = -4;
    
    public static final int DO = 0;
    public static final int DO_SHARP = 1;
    public static final int RE_FLAT = 1;
    public static final int RE = 2;
    public static final int RE_SHARP = 3;
    public static final int MI_FLAT = 3;
    public static final int MI = 4;
    public static final int FA = 5;
    public static final int FA_SHARP = 6;
    public static final int SOL_FLAT = 6;
    public static final int SOL = 7;
    public static final int SOL_SHARP = 8;
    public static final int LA_FLAT = 8;
    public static final int LA = 9;
    public static final int LA_SHARP = 10;
    public static final int SI_FLAT = 10;
    public static final int SI = 11;
    
    public int absoluteNote;
    public double volume;
    public int duration;
    public int parameter;
    
    // for actual notes:
    public MSXNote(int octave, int note, double a_volume, int a_duration) {
        absoluteNote = octave*12 + note;
        volume = a_volume;
        duration = a_duration;
    }

    // for silences:
    public MSXNote(int a_duration) {
        absoluteNote = SILENCE;
        volume = 0;
        duration = a_duration;
    }
    
    
    // for commands (e.g., repeats):
    public MSXNote(int a_command, int a_parameter) {
        absoluteNote = a_command;
        volume = 0;
        duration = 0;
        parameter = a_parameter;
    }    
}
