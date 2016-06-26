/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package musicconverter;

import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author santi
 */
public class MSXSong {
    public List<MSXNote> channels[];
    
    public MSXSong(int n_channels) {
        channels = new List[n_channels];
        for(int i = 0;i<n_channels;i++) {
            channels[i] = new ArrayList<>();
        }
    }
    
    
    public void addNote(MSXNote note, int channel) {
        channels[channel].add(note);
    }
    
    
    public int channelLength(int channel) {
        int l = 0;
        for(MSXNote n:channels[channel]) {
            l+=n.duration;
        }
        return l;
    }
    
    
    public int getNextIndex(int channel) {
        return channels[channel].size();
    }
}
