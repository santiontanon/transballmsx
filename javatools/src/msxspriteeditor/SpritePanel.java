/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package msxspriteeditor;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import javax.swing.JPanel;

/**
 *
 * @author santi
 */
public class SpritePanel extends JPanel implements MouseListener, MouseMotionListener {
    int width = 16;
    int height = 16;
    int pixelSize = 32;
    Sprite sprite = null;

    int lastClickChangeTo = 1;

    public SpritePanel(int w, int h, Sprite sp) {
        width = w;
        height = h;
        sprite = sp;
        setMinimumSize(new Dimension(width*pixelSize,height*pixelSize));  
        setPreferredSize(new Dimension(width*pixelSize,height*pixelSize));  
        addMouseListener(this);
        addMouseMotionListener(this);
        setBackground(Color.black);
        
    }
    
    
    public void clear() {
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                sprite.sprite[j][i] = 0;
            }
        }
    }
    
    public Sprite getSprite() {
        return sprite;
    }
    
    public void setSprite(Sprite sp) {
        sprite = sp;
        repaint();
    }
    
    
    public void rotate(double angle) {
        int sprite2[][] = new int[width][height];
        double radians = angle*Math.PI/180;
        double c = Math.cos(radians);
        double s = Math.sin(radians);
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                double x = (j - (width/2-0.5));
                double y = (i - (height/2-0.5));
                double x2 = x*c - y*s;
                double y2 = y*c + x*s;
                int j2 = (int)Math.round(x2 + (width/2-0.5));
                int i2 = (int)Math.round(y2 + (height/2-0.5));
                if (j2>=0 && j2<width &&
                    i2>=0 && i2<height)
                    sprite2[j][i] = sprite.sprite[j2][i2];
            }
        }
        sprite.overwrite(sprite2);
    }
    
    
    public void shift(int dx, int dy) {
        int sprite2[][] = new int[width][height];
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                int j2 = (j-dx);
                int i2 = (i-dy);
                while(j2<0) j2+=width;
                while(j2>=width) j2-=width;
                while(i2<0) i2+=height;
                while(i2>=height) i2-=height;
                sprite2[j][i] = sprite.sprite[j2][i2];
            }
        }
        sprite.overwrite(sprite2);
    }
    

    public void flip(boolean h, boolean v) {
        int sprite2[][] = new int[width][height];
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                int j2 = h ? width-(1+j):j;
                int i2 = v ? height-(1+i):i;
                sprite2[j][i] = sprite.sprite[j2][i2];
            }
        }
        sprite.overwrite(sprite2);
    }

    
    public String generateAssemblerString(String indent) {
        return sprite.generateAssemblerString(indent);
    }

    
    public void paint(Graphics g) {
        super.paint(g);
        // clear:
        g.setColor(Color.black);
        g.fillRect(0, 0, getWidth(), getHeight());
        
        g.setColor(Color.white);
        for(int i = 0;i<height;i++) {
            for(int j = 0;j<width;j++) {
                if (sprite.sprite[j][i]==1) 
                    g.fillRect(j*pixelSize, i*pixelSize, pixelSize, pixelSize);
            }
        }
        g.setColor(Color.yellow);
        for(int i = 0;i<=height;i++) {
            g.drawLine(0, i*pixelSize, width*pixelSize, i*pixelSize);
        }
        for(int j = 0;j<=width;j++) {
            g.drawLine(j*pixelSize, 0, j*pixelSize, height*pixelSize);
        }
    }    

    public void mouseClicked(MouseEvent e) {
    }

    public void mousePressed(MouseEvent e) {
        int x = e.getX()/pixelSize;
        int y = e.getY()/pixelSize;
        if (x>=0 && x<width &&
            y>=0 && y<height) {
            sprite.sprite[x][y] = 1 - sprite.sprite[x][y];
            lastClickChangeTo = sprite.sprite[x][y];
            repaint();
        }
    }

    public void mouseReleased(MouseEvent e) {
    }

    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
    }    

    public void mouseDragged(MouseEvent e) {
        int x = e.getX()/pixelSize;
        int y = e.getY()/pixelSize;
        if (x>=0 && x<width &&
            y>=0 && y<height) {
            if (sprite.sprite[x][y]!=lastClickChangeTo) {
                sprite.sprite[x][y] = lastClickChangeTo;
                repaint();
            }
        }
    }

    public void mouseMoved(MouseEvent e) {
    }
}
