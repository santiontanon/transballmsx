/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package msxspriteeditor;

import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.StringTokenizer;
import javax.swing.AbstractAction;
import javax.swing.BoxLayout;
import javax.swing.DefaultListModel;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JFrame;
import javax.swing.JList;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.KeyStroke;
import javax.swing.ListModel;
import javax.swing.ListSelectionModel;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;

/**
 *
 * @author santi
 */
public class MSXSpriteEditor extends JFrame {
    public static int spriteWidth = 16, spriteHeight = 16;
    int nextSpriteID = 1;
    
    SpritePanel spritePanel;
    JTextArea hexTextArea;
    JTextField rotateAngle;
    
    List<Sprite> sprites = new ArrayList<>();
    DefaultListModel listModel = new DefaultListModel();
    JList spriteList;
    
    public static void main(String args[]) throws Exception {
        MSXSpriteEditor w = new MSXSpriteEditor(spriteWidth, spriteHeight);
        w.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);         
        w.setVisible(true);
    }
    
    
    public MSXSpriteEditor(int w, int h) {
        setMinimumSize(new Dimension(512,768));
        setPreferredSize(new Dimension(512,768));
        
        Sprite sprite = new Sprite(spriteWidth, spriteHeight, "sprite" + nextSpriteID);
        nextSpriteID++;
        sprites.add(sprite);    
        listModel.addElement(sprite);
        
        setLayout(new BoxLayout(getContentPane(), BoxLayout.Y_AXIS));
        spritePanel = new SpritePanel(w, h, sprite);
        add(spritePanel);
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.X_AXIS));
        
        JPanel buttonPanel = new JPanel();
        buttonPanel.setLayout(new BoxLayout(buttonPanel, BoxLayout.Y_AXIS));
        
        JPanel buttonrow1 = new JPanel();
        buttonrow1.setLayout(new BoxLayout(buttonrow1, BoxLayout.X_AXIS));

        JButton b1 = new JButton("new");
        b1.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                Sprite currentSprite = spritePanel.getSprite();
                Sprite sprite = new Sprite(spriteWidth, spriteHeight, "sprite" + nextSpriteID);
                sprite.overwrite(currentSprite.sprite);
                nextSpriteID++;
                sprites.add(sprite);
                listModel.addElement(sprite);
                spriteList.setSelectedIndex(sprites.size()-1);
            }
        });
        buttonrow1.add(b1);
        JButton b_delete = new JButton("delete");
        b_delete.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                if (sprites.size()>1) {
                    int sel = spriteList.getSelectedIndex();
                    if (sel>=0) {
                        sprites.remove(sel);
                        listModel.remove(sel);
                        if (sel>=sprites.size()) sel--;
                        spriteList.setSelectedIndex(sel);
                    }
                } else {
                    spritePanel.clear();
                }
                repaint();
            }
        });
        buttonrow1.add(b_delete);
        
        JButton b2 = new JButton("clear");
        b2.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                spritePanel.clear();
                repaint();
            }
        });
        buttonrow1.add(b2);
        
        JButton b3 = new JButton("rotate");
        b3.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                try {
                    double angle = Double.parseDouble(rotateAngle.getText());
                    spritePanel.rotate(angle);
                } catch(Exception exception) {
                    exception.printStackTrace();
                }
                repaint();
            }
        });
        buttonrow1.add(b3);

        rotateAngle = new JTextField();
        rotateAngle.setText("90");
        rotateAngle.setPreferredSize(new Dimension(64,16));
        rotateAngle.setMaximumSize(new Dimension(64,16));
        buttonrow1.add(rotateAngle);
        buttonPanel.add(buttonrow1);

        JPanel buttonrow2 = new JPanel();
        buttonrow2.setLayout(new BoxLayout(buttonrow2, BoxLayout.X_AXIS));
        
        JButton b4 = new JButton("hex imp");
        b4.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                if (JOptionPane.showConfirmDialog(null, "This will delete all the sprites, are you sure to continue?", "WARNING",
                        JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
                    // yes option
                    String text = hexTextArea.getText();
                    try {
                        importHex(text);
                    }catch(Exception exception) {
                        exception.printStackTrace();
                    }
                    repaint();
                } else {
                    // no option
                }
            }
        });
        buttonrow2.add(b4);
        JButton b5 = new JButton("hex exp");
        b5.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                hexTextArea.setText(spritePanel.generateAssemblerString("    "));
                repaint();
            }
        });
        buttonrow2.add(b5);

        JButton b_exp_all = new JButton("hex expall");
        b_exp_all.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                String text = "";
                String indent = "    ";
                for(Sprite sp:sprites) {
                    String header = indent + "; " + sp.id + "\n";
                    String sp_text = sp.generateAssemblerString(indent) + "\n";
                    text += header + sp_text;
                }
                hexTextArea.setText(text);
                repaint();
            }
        });
        buttonrow2.add(b_exp_all);

        buttonPanel.add(buttonrow2);
        panel.add(buttonPanel);
        
        spriteList = new JList(listModel);
        spriteList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        spriteList.setLayoutOrientation(JList.VERTICAL);
        spriteList.setVisibleRowCount(-1);
        spriteList.addListSelectionListener(new ListSelectionListener() {
            public void valueChanged(ListSelectionEvent e) {
                for(int i = spriteList.getMinSelectionIndex();i<=spriteList.getMaxSelectionIndex();i++) {
                    if (spriteList.isSelectedIndex(i)) {
                        Sprite s = (Sprite)listModel.get(i);
                        //System.out.println("Selected " + i + " -> " + s);
                        spritePanel.setSprite(s);
                    }
                }
                repaint();
            }
        });
        JScrollPane listScroller = new JScrollPane(spriteList);
        listScroller.setPreferredSize(new Dimension(128, 64));        
        panel.add(listScroller);
        add(panel);
        
        hexTextArea = new JTextArea();
        hexTextArea.setText("    ; sprite 1\n" +
                            "    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00\n" +
                            "    db #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00");
        hexTextArea.setPreferredSize(new Dimension(512,128));
        hexTextArea.setEditable(true);
        add(hexTextArea);
        pack();
        
        
        ((JPanel)getContentPane()).getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_H,0),"flip_h");
        ((JPanel)getContentPane()).getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_V,0),"flip_v");
        ((JPanel)getContentPane()).getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_RIGHT,0),"shift_right");
        ((JPanel)getContentPane()).getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_DOWN,0),"shift_down");
        ((JPanel)getContentPane()).getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_LEFT,0),"shift_left");
        ((JPanel)getContentPane()).getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_UP,0),"shift_up");
        ((JPanel)getContentPane()).getActionMap().put("flip_h", new AbstractAction() {
            public void actionPerformed(ActionEvent actionEvent) {
                spritePanel.flip(true,false);
                repaint();
            }
        });
        ((JPanel)getContentPane()).getActionMap().put("flip_v", new AbstractAction() {
            public void actionPerformed(ActionEvent actionEvent) {
                spritePanel.flip(false,true);
                repaint();
            }
        });
        ((JPanel)getContentPane()).getActionMap().put("shift_right", new AbstractAction() {
            public void actionPerformed(ActionEvent actionEvent) {
                spritePanel.shift(1,0);
                repaint();
            }
        });
        ((JPanel)getContentPane()).getActionMap().put("shift_down", new AbstractAction() {
            public void actionPerformed(ActionEvent actionEvent) {
                spritePanel.shift(0,1);
                repaint();
            }
        });
        ((JPanel)getContentPane()).getActionMap().put("shift_left", new AbstractAction() {
            public void actionPerformed(ActionEvent actionEvent) {
                spritePanel.shift(-1,0);
                repaint();
            }
        });
        ((JPanel)getContentPane()).getActionMap().put("shift_up", new AbstractAction() {
            public void actionPerformed(ActionEvent actionEvent) {
                spritePanel.shift(0,-1);
                repaint();
            }
        });        
    }
    
    
    public void importHex(String text) throws Exception {
        List<Sprite> loadedSprites = new ArrayList<>();
        StringTokenizer st = new StringTokenizer(text,"\n");
        String currentSpriteName = null;
        List<String> currentSpriteDefinition = null;
        while(st.hasMoreTokens()) {
            String line = st.nextToken();
            StringTokenizer line_st = new StringTokenizer(line," \t,");
            if (line_st.hasMoreTokens()) {
                String first = line_st.nextToken();
                if (first.startsWith(";")) {
                    if (currentSpriteDefinition!=null) {
                        // create new sprite :
                        Sprite sp = createSpriteFromHex(currentSpriteName, currentSpriteDefinition);
                        loadedSprites.add(sp);
                    }
                    
                    // new sprite:
                    currentSpriteName = "";
                    while(line_st.hasMoreTokens()) {
                        currentSpriteName += line_st.nextToken();
                        currentSpriteName+=" ";
                    }
                    currentSpriteName = currentSpriteName.trim();
                    currentSpriteDefinition = new ArrayList<>();
                } else if (first.equals("db")) {
                    while(line_st.hasMoreTokens()) {
                        String token = line_st.nextToken();
                        if (token.startsWith("#")) currentSpriteDefinition.add(token.substring(1));
                    }
                }            
            }
        }
        if (currentSpriteDefinition!=null) {
             // create new sprite :
             Sprite sp = createSpriteFromHex(currentSpriteName, currentSpriteDefinition);
             loadedSprites.add(sp);
        }
        
        if (loadedSprites.isEmpty()) return;

        sprites.clear();
        listModel.clear();
        for(Sprite sp:loadedSprites) {
            sprites.add(sp);
            listModel.addElement(sp);
        }
        spriteList.setSelectedIndex(0);
    }
    
    
    public Sprite createSpriteFromHex(String name, List<String> hexList) throws Exception {
//        System.out.println("creating a sprite ("+name+") with " + hexList);
        
        String c[]={"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"};
        List<String> cl = Arrays.asList(c);
        int masks[] = {128,64,32,16,8,4,2,1};
        Sprite sp = new Sprite(spriteWidth, spriteHeight, name);
        if (hexList.size() != spriteHeight * spriteWidth/8) throw new Exception("creating a sprite with " + hexList.size() + " bytes!");
        
        for(int i = 0;i<hexList.size();i++) {
            String hexValue = hexList.get(i);
            int value = 0;
            value = cl.indexOf(hexValue.substring(0, 1)) * 16 + 
                    cl.indexOf(hexValue.substring(1, 2));
//            System.out.println("value: " + value);
            int x = i/16;
            int y = i%16;
            for(int j = 0;j<8;j++) {
                sp.sprite[x*8+j][y] = (value&masks[j])==0 ? 0:1;
            }
        }
        return sp;
    }
    
}
