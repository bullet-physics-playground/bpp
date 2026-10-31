// dsmcne - Program to simulate a dilute gas using DSMC algorithm
// This version simulates planar Couette flow
package physicsorig;

public class dmscne
{
     //* Initialize constants  (particle mass, diameter, etc.)
     public final double pi = 3.141592654;
     public final double boltz = 1.3806e-23;    // Boltzmann's constant (J/K)
     public double mass = 6.63e-26;       // Mass of argon atom (kg)
     public double diam = 3.66e-10;       // Effective diameter of argon atom (m)
     public double T = 273;               // Temperature (K)
     public double density = 2.685e25;    // Number density of argon at STP (m^-3)
     public double L = 1e-6;              // System size is one micron
     public double Volume = L*L*L;        // Volume of the system

     public int npart = 2000;
     public double eff_num = density*L*L*L/npart;

     public double mfp = Volume/(Math.sqrt(2.0)*pi*diam*diam*npart*eff_num);
     public double mpv = Math.sqrt(2*boltz*T/mass);  // Most probable initial velocity

     public double vwall_m = PhysicsConstants.vwall_m; //0.2;

     public double vwall = vwall_m * Math.sqrt(5./3. * boltz*T/mass);

     public MyLong seed = new MyLong();
     public Matrix x = new Matrix(npart);
     public Matrix v = new Matrix(npart,3);

     public int ncell = 20;                       // Number of cells
     public double tau = 0.2*(L/ncell)/mpv;       // Set timestep tau

     public Matrix vrmax = new Matrix(ncell);
     public Matrix selxtra = new Matrix(ncell);

     public double coeff = 0.5*eff_num*pi*diam*diam*tau/(L*L*L/ncell);

     //* Declare object for lists used in sorting
     public SortList sortData = new SortList(ncell,npart);

     //* Initialize object and variables used in statistical sampling
     public SampList sampData = new SampList(ncell);

     public double tsamp = 0;             // Total sampling time
     public Matrix dvtot = new Matrix(2);
     public Matrix dverr = new Matrix(2);


     //* Loop for the desired number of time steps
     public int colSum = 0;         // Count total collisions
     public Matrix strikes = new Matrix(2);
     public Matrix strikeSum = new Matrix(2);

     public int nstep = 2000;

     public dmscne()
     {
        seed.seed = 1;       // Initial seed for rand (DO NOT USE ZERO)
        int i;
        for( i=1; i<=npart; i++ )
        {
           x.set(i, L*rand.rand2(seed));        // Assign random positions

           // Initial velocities are Maxwell-Boltzmann distributed
           v.set(i,1, Math.sqrt(boltz*T/mass) * randn.randn2(seed));
           v.set(i,2, Math.sqrt(boltz*T/mass) * randn.randn2(seed));
           v.set(i,3, Math.sqrt(boltz*T/mass) * randn.randn2(seed));

           // Add velocity gradient to the y-component
           //System.out.println("v " + v.get(i, 2));
           v.inc(i,2, vwall * 2*(x.get(i)/L)-0.5);
           //System.out.println("v after " + v.get(i, 2));

        }
        selxtra.set(0.0);       // Used by routine "colider"
        vrmax.set(3*mpv);    // Estimated max rel. speed

        dvtot.set(0.0);               // Total momentum change at a wall
        dverr.set(0.0);               // Used to find error in dvtot

        strikeSum.set(0.0);     // Count strikes on each wall
     }

     public void timeStep()
     {
        //* Move all the particles
        Matrix delv = new Matrix(2);
        delv.set(0.0);

        mover.mover2( x, v, npart, L, mpv, vwall, tau, strikes, delv, seed );

        strikeSum.inc(1, strikes.get(1));
        strikeSum.inc(2, strikes.get(2));

        //* Sort the particles into cells
        sorter.sorter2(x,L,sortData);

        //* Evaluate collisions among the particles
        int col = colider.colider2(v,vrmax,tau,seed,selxtra,coeff,sortData);
        colSum += col;  // Increment collision count

        //* After initial transient, accumulate statistical samples
     }

   /*
   public static void main(String[] args)
   {
     //* Initialize constants  (particle mass, diameter, etc.)
     final double pi = 3.141592654;
     final double boltz = 1.3806e-23;    // Boltzmann's constant (J/K)
     double mass = 6.63e-26;       // Mass of argon atom (kg)
     double diam = 3.66e-10;       // Effective diameter of argon atom (m)
     double T = 273;               // Temperature (K)
     double density = 2.685e25;    // Number density of argon at STP (m^-3)
     double L = 1e-6;              // System size is one micron
     double Volume = L*L*L;        // Volume of the system

     //cout << "Enter number of simulation particles: ";
     int npart = 2000;
     //cin >> npart;
     double eff_num = density*L*L*L/npart;

     System.out.println("Each particle represents " + eff_num + " atoms");
     double mfp = Volume/(Math.sqrt(2.0)*pi*diam*diam*npart*eff_num);
     System.out.println("System width is " + L/mfp + " mean free paths");
     double mpv = Math.sqrt(2*boltz*T/mass);  // Most probable initial velocity

     //cout << "Enter wall velocity as Mach number: ";
     double vwall_m = 0.2;
     //cin >> vwall_m;

     double vwall = vwall_m * Math.sqrt(5./3. * boltz*T/mass);
     System.out.println("Wall velocities are " + -vwall + " and " +
                        vwall + " m/s");

     //* Assign random positions and velocities to particles
     MyLong seed = new MyLong();
     seed.seed = 1;       // Initial seed for rand (DO NOT USE ZERO)
     Matrix x = new Matrix(npart);
     Matrix v = new Matrix(npart,3);

     int i;
     for( i=1; i<=npart; i++ )
     {
        x.set(i, L*rand.rand2(seed));        // Assign random positions
        //x.set(i, L*Math.random());

        // Initial velocities are Maxwell-Boltzmann distributed
        v.set(i,1, Math.sqrt(boltz*T/mass) * randn.randn2(seed));
        v.set(i,2, Math.sqrt(boltz*T/mass) * randn.randn2(seed));
        v.set(i,3, Math.sqrt(boltz*T/mass) * randn.randn2(seed));

        // Add velocity gradient to the y-component
        v.inc(i,2, vwall * 2*(x.get(i)/L - 0.5));

     }

     //* Initialize variables used for evaluating collisions
     int ncell = 20;                       // Number of cells
     double tau = 0.2*(L/ncell)/mpv;       // Set timestep tau

     Matrix vrmax = new Matrix(ncell);
     Matrix selxtra = new Matrix(ncell);

     vrmax.set(3*mpv);    // Estimated max rel. speed
     selxtra.set(0.0);       // Used by routine "colider"

     double coeff = 0.5*eff_num*pi*diam*diam*tau/(L*L*L/ncell);

     //* Declare object for lists used in sorting
     SortList sortData = new SortList(ncell,npart);

     //* Initialize object and variables used in statistical sampling
     SampList sampData = new SampList(ncell);

     double tsamp = 0;             // Total sampling time
     Matrix dvtot = new Matrix(2);
     Matrix dverr = new Matrix(2);

     dvtot.set(0.0);               // Total momentum change at a wall
     dverr.set(0.0);               // Used to find error in dvtot

     //* Loop for the desired number of time steps
     int colSum = 0;         // Count total collisions
     Matrix strikes = new Matrix(2);
     Matrix strikeSum = new Matrix(2);

     strikeSum.set(0.0);     // Count strikes on each wall

     //cout << "Enter total number of time steps: ";
     int nstep = 1000;
     //cin >> nstep;
     int istep;
     for( istep = 1; istep<=nstep; istep++ )
     {
        //* Move all the particles
        Matrix delv = new Matrix(2);
        delv.set(0.0);

        mover.mover2( x, v, npart, L, mpv, vwall, tau, strikes, delv, seed );

        strikeSum.inc(1, strikes.get(1));
        strikeSum.inc(2, strikes.get(2));

        //* Sort the particles into cells
        sorter.sorter2(x,L,sortData);

        //* Evaluate collisions among the particles
        int col = colider.colider2(v,vrmax,tau,seed,selxtra,coeff,sortData);
        colSum += col;  // Increment collision count

        //* After initial transient, accumulate statistical samples
        if(istep > nstep/10)
        {

           sampler.sampler2(x,v,npart,L,sampData);
           // Cummulative velocity change for particles striking walls
           dvtot.inc(1, delv.get(1));
           dvtot.inc(2, delv.get(2));

           dverr.inc(1, delv.get(1)*delv.get(1));
           dverr.inc(2, delv.get(2)*delv.get(2));

           tsamp += tau;
        }

        //* Periodically display the current progress
        if( (istep%100) < 1 )
        {
           System.out.println("Done " + istep + " of " + nstep + " steps; " +
                              colSum + " collisions");
           System.out.println("Total wall strikes: " + strikeSum.get(1) + " (left) " +
                              strikeSum.get(2) + " (right)");
        }
     }

     //* Normalize the accumulated statistics
     int nsamp = sampData.nsamp;
     for( i=1; i<=ncell; i++ )
     {
        sampData.ave_n[i] *= (eff_num/(Volume/ncell))/nsamp;
        sampData.ave_ux[i] /= nsamp;
        sampData.ave_uy[i] /= nsamp;
        sampData.ave_uz[i] /= nsamp;
        sampData.ave_T[i] *= mass/(3*boltz*nsamp);
     }

     dverr.set(1, dverr.get(1)/(nsamp-1) - (dvtot.get(1)/nsamp)*(dvtot.get(1)/nsamp));
     dverr.set(1, Math.sqrt(dverr.get(1)*nsamp));
     dverr.set(2, dverr.get(2)/(nsamp-1) - (dvtot.get(2)/nsamp)*(dvtot.get(2)/nsamp));
     dverr.set(2, Math.sqrt(dverr.get(2)*nsamp));

     //* Compute viscosity from drag force on the walls
     Matrix force = new Matrix(2);
     Matrix ferr = new Matrix(2);

     force.set(1, (eff_num*mass*dvtot.get(1))/(tsamp*L*L));
     force.set(2, (eff_num*mass*dvtot.get(2))/(tsamp*L*L));
     ferr.set(1, (eff_num*mass*dverr.get(1))/(tsamp*L*L));
     ferr.set(2, (eff_num*mass*dverr.get(2))/(tsamp*L*L));

     System.out.println("Force per unit area is");
     System.out.println("Left wall:  " + force.get(1) + " +/- " + ferr.get(1));
     System.out.println("Right wall: " + force.get(2) + " +/- " + ferr.get(2));

     double vgrad = 2*vwall/L;    // Velocity gradient
     double visc = 0.5*(-force.get(1)+force.get(2))/vgrad;  // Average viscosity
     double viscerr = 0.5*(ferr.get(1)+ferr.get(2))/vgrad;  // Error

     System.out.println("Viscosity = " + visc + " +/- " + viscerr + "N s/m^2");
     double eta = 5.*pi/32.*mass*density*(2./Math.sqrt(pi)*mpv)*mfp;

     System.out.println("Theoretical value of viscoisty is " + eta + "N s/m^2");
   }*/
}