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
public class TransballSong {
    
    public static int BASE_TEMPO = 1;
    
    public static MSXSong createTransballSong() {
        MSXSong song = new MSXSong(3);
        
        // measure 1
        bassline(song, 0, 1.0);
        song.addNote(new MSXNote(BASE_TEMPO*64), 1);
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);
        
        // measure 2
        bassline(song, 0, 1.0); 
        arpegios(song, 1, 1.0);
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);
        
        // measure 3
        bassline(song, 0, 1.0); 
        arpegios(song, 1, 1.0);
        melodyv1(song, 2, 1.0);
        
        // measure 4
        bassline(song, 0, 1.0); 
        arpegios(song, 1, 1.0);
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);

        // measure 5
        bassline(song, 0, 1.0); 
        arpegios(song, 1, 1.0);
        melodyv2(song, 2, 1.0);
        return song;
    }
    
    
    public static MSXSong createTransballSongWithGotos() {
        MSXSong song = new MSXSong(3);
        
        // bass line:
        int bass_repeat_index = song.getNextIndex(0);
        bassline(song, 0, 1.0);
        song.addNote(new MSXNote(MSXNote.GOTO, bass_repeat_index), 0);
        
        // arpegios:
        song.addNote(new MSXNote(BASE_TEMPO*64), 1);
        int arpegios_repeat_index = song.getNextIndex(1);
        arpegios(song, 1, 1.0);
        song.addNote(new MSXNote(MSXNote.GOTO, arpegios_repeat_index), 1);
        
        // melody:
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);        
        int melody_repeat_index = song.getNextIndex(2);
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);        
        melodyv1(song, 2, 1.0);
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);
        melodyv2(song, 2, 1.0);
        song.addNote(new MSXNote(MSXNote.GOTO, melody_repeat_index), 2);
        return song;
    }    

    
    public static MSXSong createTransballSongWithRepeats() {
        MSXSong song = new MSXSong(3);
        
        // bass line:
        int bass_repeat_index = song.getNextIndex(0);
        song.addNote(new MSXNote(MSXNote.REPEAT, 4), 0);
        basslineWithRepeats(song, 0, 1.0);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), 0);
        basslineWithRepeatsPart2(song, 0, 1.0);
        song.addNote(new MSXNote(MSXNote.GOTO, bass_repeat_index), 0);
        
        // arpegios:
        int arpegios_repeat_index = song.getNextIndex(1);
        song.addNote(new MSXNote(BASE_TEMPO*64), 1);
        song.addNote(new MSXNote(MSXNote.REPEAT, 3), 1);
        arpegiosWithRepeats(song, 1, 1.0);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), 1);
        arpegiosWithRepeatsPart2(song, 1, 1.0);
        song.addNote(new MSXNote(MSXNote.GOTO, arpegios_repeat_index), 1);
        
        // melody:
        int melody_repeat_index = song.getNextIndex(2);
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);        
        song.addNote(new MSXNote(BASE_TEMPO*64), 2);        
        melodyv1(song, 2, 1.0);
        melodyv2(song, 2, 1.0);
        melodyv3(song, 2, 1.0);
        song.addNote(new MSXNote(MSXNote.GOTO, melody_repeat_index), 2);
        return song;
    }    
    

    public static void melodyv1(MSXSong song, int channel, double volume) {
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(4,MSXNote.SI,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.DO,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);
        song.addNote(new MSXNote(5,MSXNote.DO,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(4,MSXNote.SI,volume,BASE_TEMPO*15), channel);
        song.addNote(new MSXNote(4,MSXNote.SI,0,BASE_TEMPO), channel);        

        song.addNote(new MSXNote(4,MSXNote.SI,volume,BASE_TEMPO*15), channel);
        song.addNote(new MSXNote(4,MSXNote.SI,0,BASE_TEMPO), channel);        
    }
    
    
    public static void melodyv2(MSXSong song, int channel, double volume) {
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(4,MSXNote.SI,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.DO,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);
        song.addNote(new MSXNote(5,MSXNote.DO,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*7), channel);
        song.addNote(new MSXNote(1), channel);        
        song.addNote(new MSXNote(5,MSXNote.SOL,volume,BASE_TEMPO*4), channel);
        song.addNote(new MSXNote(5,MSXNote.FA,volume,BASE_TEMPO*4), channel);

        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*15), channel);
        song.addNote(new MSXNote(1), channel);  
    }
    

    public static void melodyv3(MSXSong song, int channel, double volume) {
        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);
        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.DO,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);
        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.FA,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);        
        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);  
        song.addNote(new MSXNote(5,MSXNote.DO,volume,BASE_TEMPO*4), channel);

        song.addNote(new MSXNote(5,MSXNote.LA,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);        
        song.addNote(new MSXNote(5,MSXNote.SOL,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.FA,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.SOL,volume,BASE_TEMPO*11), channel);
        song.addNote(new MSXNote(1), channel);        
        song.addNote(new MSXNote(5,MSXNote.FA,volume,BASE_TEMPO*2), channel);
        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*2), channel);

        song.addNote(new MSXNote(5,MSXNote.RE,volume,BASE_TEMPO*15), channel);
        song.addNote(new MSXNote(1), channel);        

        song.addNote(new MSXNote(5,MSXNote.MI,volume,BASE_TEMPO*15), channel);
        song.addNote(new MSXNote(1), channel);        
    }

    
    public static void bassline(MSXSong song, int channel, double volume) {
        MSXNote low_la = new MSXNote(1,MSXNote.LA,volume,BASE_TEMPO*2);
        MSXNote high_la = new MSXNote(2,MSXNote.LA,volume,BASE_TEMPO*2);
        MSXNote low_fa = new MSXNote(1,MSXNote.FA,volume,BASE_TEMPO*2);
        MSXNote high_fa = new MSXNote(2,MSXNote.FA,volume,BASE_TEMPO*2);
        MSXNote low_sol = new MSXNote(1,MSXNote.SOL,volume,BASE_TEMPO*2);
        MSXNote high_sol = new MSXNote(2,MSXNote.SOL,volume,BASE_TEMPO*2);
        MSXNote low_mi = new MSXNote(1,MSXNote.MI,volume,BASE_TEMPO*2);
        MSXNote high_mi = new MSXNote(2,MSXNote.MI,volume,BASE_TEMPO*2);

        for(int i = 0;i<4;i++) {
            song.addNote(low_la, channel);
            song.addNote(high_la, channel);
        }
        for(int i = 0;i<4;i++) {
            song.addNote(low_fa, channel);
            song.addNote(high_fa, channel);
        }
        for(int i = 0;i<4;i++) {
            song.addNote(low_sol, channel);
            song.addNote(high_sol, channel);
        }
        for(int i = 0;i<4;i++) {
            song.addNote(low_mi, channel);
            song.addNote(high_mi, channel);
        }
    }
 
    
    public static void basslineWithRepeats(MSXSong song, int channel, double volume) {
        MSXNote low_la = new MSXNote(1,MSXNote.LA,volume,BASE_TEMPO*2);
        MSXNote high_la = new MSXNote(2,MSXNote.LA,volume,BASE_TEMPO*2);
        MSXNote low_fa = new MSXNote(1,MSXNote.FA,volume,BASE_TEMPO*2);
        MSXNote high_fa = new MSXNote(2,MSXNote.FA,volume,BASE_TEMPO*2);
        MSXNote low_sol = new MSXNote(1,MSXNote.SOL,volume,BASE_TEMPO*2);
        MSXNote high_sol = new MSXNote(2,MSXNote.SOL,volume,BASE_TEMPO*2);
        MSXNote low_mi = new MSXNote(1,MSXNote.MI,volume,BASE_TEMPO*2);
        MSXNote high_mi = new MSXNote(2,MSXNote.MI,volume,BASE_TEMPO*2);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_la, channel);
        song.addNote(high_la, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_fa, channel);
        song.addNote(high_fa, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_sol, channel);
        song.addNote(high_sol, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_mi, channel);
        song.addNote(high_mi, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);
    }
    
    
    public static void basslineWithRepeatsPart2(MSXSong song, int channel, double volume) {
        MSXNote low_do = new MSXNote(1,MSXNote.DO,volume,BASE_TEMPO*2);
        MSXNote high_do = new MSXNote(2,MSXNote.DO,volume,BASE_TEMPO*2);
        MSXNote low_re = new MSXNote(1,MSXNote.RE,volume,BASE_TEMPO*2);
        MSXNote high_re = new MSXNote(2,MSXNote.RE,volume,BASE_TEMPO*2);
        MSXNote low_mi = new MSXNote(1,MSXNote.MI,volume,BASE_TEMPO*2);
        MSXNote high_mi = new MSXNote(2,MSXNote.MI,volume,BASE_TEMPO*2);
        MSXNote low_fa = new MSXNote(1,MSXNote.FA,volume,BASE_TEMPO*2);
        MSXNote high_fa = new MSXNote(2,MSXNote.FA,volume,BASE_TEMPO*2);
        MSXNote low_sol = new MSXNote(1,MSXNote.SOL,volume,BASE_TEMPO*2);
        MSXNote high_sol = new MSXNote(2,MSXNote.SOL,volume,BASE_TEMPO*2);
        MSXNote low_la = new MSXNote(1,MSXNote.LA,volume,BASE_TEMPO*2);
        MSXNote high_la = new MSXNote(2,MSXNote.LA,volume,BASE_TEMPO*2);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_do, channel);
        song.addNote(high_do, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_sol, channel);
        song.addNote(high_sol, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_re, channel);
        song.addNote(high_re, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_la, channel);
        song.addNote(high_la, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_fa, channel);
        song.addNote(high_fa, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_do, channel);
        song.addNote(high_do, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_sol, channel);
        song.addNote(high_sol, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 4), channel);
        song.addNote(low_mi, channel);
        song.addNote(high_mi, channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT,0), channel);
    }            
    
    
    public static void arpegios(MSXSong song, int channel, double volume) {
        
        for(int i = 0;i<2;i++) {
            song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        }
        for(int i = 0;i<2;i++) {
            song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        }
        for(int i = 0;i<2;i++) {
            song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        }
        for(int i = 0;i<2;i++) {
            song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
            song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        }
    }
    
    
    public static void arpegiosWithRepeats(MSXSong song, int channel, double volume) {
        
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
    
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);

        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
    }    


    public static void arpegiosWithRepeatsPart2(MSXSong song, int channel, double volume) {
        
        // DO
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);        

        // SOL
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
        
        // RE
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
        
        // LA
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
        
        // FA
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.LA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.FA,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
        
        // DO
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.DO,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);        
        
        // SOL
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.RE,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
        
        // MI
        song.addNote(new MSXNote(MSXNote.REPEAT, 2), channel);
        song.addNote(new MSXNote(3,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.SOL,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(3,MSXNote.SI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(4,MSXNote.MI,volume,BASE_TEMPO), channel);
        song.addNote(new MSXNote(MSXNote.END_REPEAT, 0), channel);
    }    

}
