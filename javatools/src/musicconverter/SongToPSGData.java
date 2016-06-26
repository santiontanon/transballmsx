/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package musicconverter;

import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;

/**
 *
 * @author santi
 */
public class SongToPSGData {
    
    public static double PSG_Master_Frequency = 111861; // Hz
    public static double noteFrequencies[] = {
                            // do1:
                            32.703, 34.648, 36.708, 38.891, 41.203, 43.654, 46.249, 48.999, 51.913, 55.000, 58.270, 61.735,
                            // do2:
                            65.406, 69.296, 73.416, 77.782, 82.407, 87.307, 92.499, 97.999, 103.83, 110.00, 116.54, 123.47,
                            // do3:
                            130.81, 138.59, 146.83, 155.56, 164.81, 174.61, 185, 196, 207.65, 220.00, 233.08, 246.94,
                            // do4:
                            261.63, 277.18, 293.67, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440.00, 466.16, 493.88,
                            // do5:
                            523.25, 554.37, 587.33, 622.25, 659.26, 698.46, 739.99, 783.99, 830.61, 880, 932.33, 987.77,
                            // do6:
                            1046.5, 1108.7, 1174.7, 1244.5, 1318.5, 1396.9, 1480.0, 1568.0, 1661.2, 1760.0, 1864.7, 1975.5,
                            // do7:
                            2093.0, 2217.5, 2349.3, 2489.0, 2637.0, 2793.0, 2960.0, 3136.0, 3322.4, 3520.0, 3729.3, 3951.1,
                            // do8:
                            4186.0    
                            };
    public static String goto_command = "SFX_GOTO";
    public static String wait_command = "SFX_SKIP";
    public static String multi_wait_command = "SFX_MULTISKIP";
    public static String end_command = "SFX_END";
    

    public static void convert(MSXSong song) throws Exception {
        List<String> PSGcommands = new ArrayList<>();
        
        int time = 0;
        int nchannels = song.channels.length;
        int nextNote[] = new int[nchannels];
        int channelTime[] = new int[nchannels];
        double lastChannelVolume[] = new double[nchannels];
        
        for(int i = 0;i<nchannels;i++) {
            nextNote[i] = 0;
            channelTime[i] = 0;
            lastChannelVolume[i] = -1;
        }

        boolean notesLeft = false;
        PSGcommands.add("    db 7,#b8");
        do {
//            System.out.println(time + " - " + channelTime[0]);
            notesLeft = false;
            for(int i = 0;i<nchannels;i++) {
                if (song.channels[i].size()>nextNote[i]) {
                    notesLeft = true;
                    if (channelTime[i]<=time) {
                        MSXNote note = song.channels[i].get(nextNote[i]);

                        // produce commands:
                        if (note.absoluteNote == MSXNote.SILENCE) {
                            PSGcommands.add(PSGVolumeCommand(i, 0));                            
                        } else if (note.absoluteNote == MSXNote.GOTO) {
                            throw new Exception("goto command found in basic PSG converter!");
                        } else {
                            PSGcommands.add(PSGNoteCommand(i, note.absoluteNote));
                            if (lastChannelVolume[i]!=note.volume) {
                                PSGcommands.add(PSGVolumeCommand(i, note.volume));
                                lastChannelVolume[i] = note.volume;
                            }
                        }

                        channelTime[i] += note.duration;
                        nextNote[i]++;
                    }
                }
            }
            PSGcommands.add("    db " + wait_command);
            time++;
        }while(notesLeft);
        PSGcommands.add("    db " + end_command);
        
        int lengthInBytes = 0;
        
        for(String command:PSGcommands) {
            System.out.println(command);
            
            StringTokenizer st = new StringTokenizer(command,",");
            while(st.hasMoreTokens()) {
                lengthInBytes++;
                st.nextToken();
            }
        }
        System.out.println(";; song length in bytes: " + lengthInBytes);
    }
    
    
    public static int convertByChannel(MSXSong song, String channelName, int channel, boolean initBlock) throws Exception {
        List<String> PSGcommands = new ArrayList<>();
        List<Integer> indexes = new ArrayList<>();
        
        int time = 0;
        int nextNote = 0;
        int channelTime = 0;
        double lastChannelVolume = -1;
        
        boolean notesLeft = false;
        int n_waits_in_a_row = 0;
        
        System.out.println(channelName + ":");      
        
        if (initBlock) {
            PSGcommands.add("    db 7,#b8");
        }
        do {
//            System.out.println(time + " - " + channelTime[0]);
            notesLeft = false;
            if (song.channels[channel].size()>nextNote) {
                notesLeft = true;
                    if (channelTime<=time) {
                    if (n_waits_in_a_row<=2) {
                        for(int i = 0;i<n_waits_in_a_row;i++) {
                            PSGcommands.add("    db " + wait_command);
                        }
                    } else {
                        PSGcommands.add("    db " + multi_wait_command + "," + n_waits_in_a_row);
                    }
                    n_waits_in_a_row = 0;
                    indexes.add(commandsLengthInBytes(PSGcommands));
                    MSXNote note = song.channels[channel].get(nextNote);

                    // produce commands:
                    if (note.absoluteNote == MSXNote.SILENCE) {
                        PSGcommands.add(PSGVolumeCommand(channel, 0));                            
                        lastChannelVolume = 0;
                    } else if (note.absoluteNote == MSXNote.GOTO) {
                        PSGcommands.add("    db " + goto_command);
                        PSGcommands.add("    dw " + channelName + "+" + indexes.get(note.parameter));
                    } else {
                        PSGcommands.add(PSGNoteCommand(channel, note.absoluteNote));
                        if (lastChannelVolume!=note.volume) {
                            PSGcommands.add(PSGVolumeCommand(channel, note.volume));
                            lastChannelVolume = note.volume;
                        }
                    }

                    channelTime += note.duration;
                    nextNote++;
                }
            }
            n_waits_in_a_row++;
//            PSGcommands.add("    db " + wait_command);
            time++;
        }while(notesLeft);
        if (n_waits_in_a_row<=2) {
            for(int i = 0;i<n_waits_in_a_row;i++) {
                PSGcommands.add("    db " + wait_command);
            }
        } else {
            PSGcommands.add("    db " + multi_wait_command + "," + n_waits_in_a_row);
        }
        PSGcommands.add("    db " + end_command);
        
        
        for(String command:PSGcommands) {
            System.out.println(command + "\t;; " + commandLengthInBytes(command));
        }
        int lengthInBytes = commandsLengthInBytes(PSGcommands);
        System.out.println(";; channel " + channel + " length in bytes: " + lengthInBytes);
        return lengthInBytes;
    }
        

    public static int commandsLengthInBytes(List<String> commands) throws Exception {
        int lengthInBytes = 0;
        for(String command:commands) {
            lengthInBytes += commandLengthInBytes(command);
        }
        return lengthInBytes;
    }
    
    public static int commandLengthInBytes(String command) throws Exception {
        int lengthInBytes = 0;
        int unit = 1;
        StringTokenizer st1 = new StringTokenizer(command," \t,");
        String header = st1.nextToken();
        if (header.equals("db")) unit = 1;
        else if (header.equals("dw")) unit = 2;
        else throw new Exception("Command dows not start with db or dw!");
        StringTokenizer st2 = new StringTokenizer(command,",");
        while(st2.hasMoreTokens()) {
            lengthInBytes+=unit;
            st2.nextToken();
        }
        return lengthInBytes;
    }
    
    
    public static String toHexByte(int n) {
        char hex[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
        return "" + hex[n/16] + hex[n%16];
    }
    
    
    public static int PSGNoteInterval(double desiredFrequency) {
        return (int)Math.round(PSG_Master_Frequency/desiredFrequency);
    }
    
    public static String PSGNoteCommand(int channel, int absoluteNote) {
        int period = PSGNoteInterval(noteFrequencies[absoluteNote]);
        return "    db " + (channel*2+1) + ",#" + toHexByte(period/256) + 
                 "," + (channel*2) + ",#" + toHexByte(period%256);
    }
    
    
    public static String PSGVolumeCommand(int channel, double volume) {
        return "    db " + (channel+8) + ",#" + toHexByte(0 + ((int)(volume*15)));
    }
}
