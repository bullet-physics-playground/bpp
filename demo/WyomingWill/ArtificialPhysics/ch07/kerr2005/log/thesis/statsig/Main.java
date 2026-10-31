
import java.io.*;

public class Main {

  public static String[] variables     = { "kt", "ap", "ant", "fsm", "simple" };
  public static StringBuffer outputN   = new StringBuffer();
  public static StringBuffer outputPct = new StringBuffer();
  public static double pValue          = 0.05;

  public Main(int index) {
    outputN.append("myP = zeros(1,1);\n");
    outputN.append(variables[index]+"H_n = zeros("+((variables.length-1)*18)+",1);\n");
    int count = 0;
    for (int i = 0; i < variables.length; ++i) { 
      if (i == index) continue;

      for (int j = 5; j < 35; j+=5) {
        ++count;
        outputN.append("[myP, " + variables[index]+"H_n(" + count + ",1)] = ranksum("); 
        outputN.append(variables[index] + "_N_" + j + "_be, ");
        outputN.append(variables[i] + "_N_" + j + "_be, " + pValue + ");\n");

        ++count;
        outputN.append("[myP, " + variables[index]+"H_n(" + count + ",1)] = ranksum(");
        outputN.append(variables[index] + "_N_" + j + "_to, ");
        outputN.append(variables[i] + "_N_" + j + "_to, " + pValue + ");\n");
        
        ++count;
        outputN.append("[myP, " + variables[index]+"H_n(" + count + ",1)] = ranksum(");
        outputN.append(variables[index] + "_N_" + j + "_ti, ");
        outputN.append(variables[i] + "_N_" + j + "_ti, " + pValue + ");\n");
      }
    }

    outputPct.append("meP = zeros(1,1);\n");
    outputPct.append(variables[index]+"H_p = zeros("+((variables.length-1)*18)+",1);\n");
    count = 0;
    for (int i = 0; i < variables.length; ++i) {
      if (i == index) continue;
      for (int j = 0; j < 50; j+=10) {
        if (j != 0) {
          ++count;
          outputPct.append("[meP, " + variables[index]+"H_p(" + count + ",1)] = ranksum(");
          outputPct.append(variables[index] + "_PCT_" + j + "_be, ");
          outputPct.append(variables[i] + "_PCT_" + j + "_be, " + pValue + ");\n");
        }

        ++count;
        outputPct.append("[meP, " + variables[index]+"H_p(" + count + ",1)] = ranksum(");
        outputPct.append(variables[index] + "_PCT_" + j + "_to, ");
        outputPct.append(variables[i] + "_PCT_" + j + "_to, " + pValue + ");\n");

        ++count;
        outputPct.append("[meP, " + variables[index]+"H_p(" + count + ",1)] = ranksum(");
        outputPct.append(variables[index] + "_PCT_" + j + "_ti, ");
        outputPct.append(variables[i] + "_PCT_" + j + "_ti, " + pValue + ");\n");
      }
    }

  }

  public static void main(String[] args) {
    Main m = new Main(0);
    Main m2 = new Main(1);
    try {
        BufferedWriter out1 = new BufferedWriter(new FileWriter("matlab_n.m"));
        out1.write(m.outputN.toString());
        out1.close();
       
        BufferedWriter out2 = new BufferedWriter(new FileWriter("matlab_pct.m"));
        out2.write(m.outputPct.toString()); 
        out2.close();
    } catch (Exception e) {
        System.out.println("ERROR " + e.getMessage());
    }
  }
}
