/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package musicconverter;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.StringTokenizer;

/**
 *
 * @author santi
 */
public class SongToPSGDataV2 {
    
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
    

    public static int convertByChannel(MSXSong song, String channelName, int channel, boolean initBlock) throws Exception {
        List<PSGCommand> PSGcommands = new ArrayList<>();
        List<Integer> indexes = new ArrayList<>();
        
        int time = 0;
        int nextNote = 0;
        int channelTime = 0;
        double lastChannelVolume = -1;
        
        boolean notesLeft = false;
        int n_waits_in_a_row = 0;
        
        System.out.println(channelName + ":");      
        
        if (initBlock) {
            PSGcommands.add(new PSGCommand(PSGCommand.PSG_COMMAND, 7, 184));
        }
        do {
//            System.out.println(time + " - " + channelTime[0]);
            notesLeft = false;
            if (song.channels[channel].size()>nextNote) {
                notesLeft = true;
                while (channelTime<=time && song.channels[channel].size()>nextNote) {
                    if (n_waits_in_a_row<=2) {
                        for(int i = 0;i<n_waits_in_a_row;i++) {
                            PSGcommands.add(new PSGCommand(PSGCommand.SKIP_COMMAND, 0, 0));
                        }
                    } else {
                        PSGcommands.add(new PSGCommand(PSGCommand.MULTISKIP_COMMAND, 0, n_waits_in_a_row));
                    }
                    n_waits_in_a_row = 0;
                    indexes.add(commandsLengthInBytes(PSGcommands));
                    MSXNote note = song.channels[channel].get(nextNote);

                    // produce commands:
                    if (note.absoluteNote == MSXNote.SILENCE) {
                        PSGcommands.add(PSGVolumeCommand(channel, 0));                            
                        lastChannelVolume = 0;
                    } else if (note.absoluteNote == MSXNote.GOTO) {
                        PSGcommands.add(new PSGCommand(PSGCommand.GOTO_COMMAND,0,indexes.get(note.parameter)));
                    } else if (note.absoluteNote == MSXNote.REPEAT) {
                        PSGcommands.add(new PSGCommand(PSGCommand.REPEAT_COMMAND,0,note.parameter));
                    } else if (note.absoluteNote == MSXNote.END_REPEAT) {
                        PSGcommands.add(new PSGCommand(PSGCommand.END_REPEAT_COMMAND,0,0));
                    } else {
                        PSGcommands.addAll(PSGNoteCommand(channel, note.absoluteNote));
                        if (lastChannelVolume!=note.volume) {
                            PSGcommands.add(PSGVolumeCommand(channel, note.volume));
                            lastChannelVolume = note.volume;
                        }
                    }

                    channelTime += note.duration;
                    nextNote++;
                }
                n_waits_in_a_row++;
            }
//            PSGcommands.add("    db " + wait_command);
            time++;
        }while(notesLeft);
        if (n_waits_in_a_row<=2) {
            for(int i = 0;i<n_waits_in_a_row;i++) {
                PSGcommands.add(new PSGCommand(PSGCommand.SKIP_COMMAND, 0, 0));
            }
        } else {
            PSGcommands.add(new PSGCommand(PSGCommand.MULTISKIP_COMMAND, 0, n_waits_in_a_row));
        }
        PSGcommands.add(new PSGCommand(PSGCommand.END_COMMAND, 0, 0));
        
        int length = 0;
        HashMap<Integer,Integer> registerState = new HashMap<>();
        for(PSGCommand command:PSGcommands) {
            System.out.print(command.toString(channelName, registerState));
            length+=command.lastLengthInBytes();
        }
        System.out.println(";; channel " + channel + " length in bytes: " + length);
        return length;
    }
        

    public static int commandsLengthInBytes(List<PSGCommand> commands) throws Exception {
        int lengthInBytes = 0;
        for(PSGCommand command:commands) {
            lengthInBytes += command.lengthInBytes();
        }
        return lengthInBytes;
    }
            
    
    public static int PSGNoteInterval(double desiredFrequency) {
        return (int)Math.round(PSG_Master_Frequency/desiredFrequency);
    }
    
    public static List<PSGCommand> PSGNoteCommand(int channel, int absoluteNote) {
        int period = PSGNoteInterval(noteFrequencies[absoluteNote]);
        List<PSGCommand> l = new ArrayList<>();
        l.add(new PSGCommand(PSGCommand.PSG_COMMAND, channel*2+1, period/256));
        l.add(new PSGCommand(PSGCommand.PSG_COMMAND, channel*2, period%256));
        return l;
    }
    
    
    public static PSGCommand PSGVolumeCommand(int channel, double volume) {
        return new PSGCommand(PSGCommand.PSG_COMMAND, channel+8, (int)(volume*15));
    }
}
