/*
 * ValueDialog.java
 *
 * Created on September 8, 2004, 4:14 PM
 */

package graphics.collision;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
/**
 *
 * @author  wkerr
 */
public class ValueDialog extends JDialog {

    /** Creates a new instance of ValueDialog */
    public ValueDialog(JFrame owner) {
        super(owner, true);
        addComponents();
        addListeners();
    }

    private void addComponents() {
        getContentPane().setLayout(new GridBagLayout());

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("A x"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 0;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(axField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 1;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("A y"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 1;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(ayField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 2;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("A vx"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 2;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(avxField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 3;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("A vy"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 3;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(avyField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 4;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("B x"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 4;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(bxField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 5;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("B y"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 5;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(byField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 6;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("B vx"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 6;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(bvxField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 7;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(new JLabel("B vy"), gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 1;
        gbc.gridy = 7;
        gbc.weightx = 0.5;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(bvyField, gbc);

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 8;
        gbc.gridwidth = 2;
        gbc.fill = GridBagConstraints.BOTH;
        getContentPane().add(okButton, gbc);

    }

    private void addListeners() {
        okButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                double ax = Double.parseDouble(axField.getText());
                double ay = Double.parseDouble(ayField.getText());
                double avx = Double.parseDouble(avxField.getText());
                double avy = Double.parseDouble(avyField.getText());
                double bx = Double.parseDouble(bxField.getText());
                double by = Double.parseDouble(byField.getText());
                double bvx = Double.parseDouble(bvxField.getText());
                double bvy = Double.parseDouble(bvyField.getText());

                Observer.inst().setValues(ax, ay, avx, avy, bx, by, bvx, bvy);
                dispose();
            }
        });
    }

    private JButton okButton = new JButton("OK");
    public JTextField axField = new JTextField();
    public JTextField ayField = new JTextField();
    public JTextField avxField = new JTextField();
    public JTextField avyField = new JTextField();

    public JTextField bxField = new JTextField();
    public JTextField byField = new JTextField();
    public JTextField bvxField = new JTextField();
    public JTextField bvyField = new JTextField();

}
