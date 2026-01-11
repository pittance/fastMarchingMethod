//from:
//  https://sbgf.org.br/mysbgf/eventos/expanded_abstracts/17th_CISBGf/181620210529230327sbgf_FMM.pdf
//notes:
//  this shows some FORTRAN code which has a bunch of module-level variables
//  I didn't change this structure

class FMM {
  int izs,ixs;        //source position indices
  int nz,nx;          //model size
  float dz,dx;        //sampling
  float[][] slowness; //slowness
  float[][] tmap;     //travel time map (output)
  float[][] t;        //time (internal, used for calculations)
  char[][] tag;       //grid flags
  int iz,ix;          //grid indices
  int nclose,iclose;  //close counter and index
  int min_iclose;     //min close point index
  int max_iclose;     //max close point index
  float a,b,c,delta;  //quadratic coefficients
  float twoside;      //twoside time update
  float onesidez;     //oneside time update z
  float onesidex;     //oneside time update x
  float pz,px;        //fd coefficient
  float th,tv;        //neighbour time distance
  
  Heap_struc[] heap;
  

  FMM(int izs, int ixs, int nz, int nx, int dz, int dx, float[][] slowness) {
    this.izs = izs;
    this.ixs = ixs;
    this.nz = nz;
    this.nx = nx;
    this.dz = dz;
    this.dx = dx;
    this.slowness = slowness;
    
    //NB for t and tag:
    //  FORTRAN indices go from -1 to nz+2 and this is no bueno in Java
    //  so we shift up by one so the ranges are
    //    -1:nz+2 ==maps to==> 0:nz+3
    //  we then have a function to map between these indices:
    //    ji gives java indices (for data access) from fortran numbering (from calculations)
    t = new float[nz+3][nx+3];
    tmap = new float[nz][nx];
    tag = new char[nz+3][nx+3];
    heap = new Heap_struc[nz*nx];
    for (int i=0;i<heap.length;i++) heap[i] = new Heap_struc();
    
    
    
  }
  
  void initialise() {
    
    println("setting t array to large");
    for(int i=0;i<t.length;i++) {
      for(int j=0;j<t[0].length;j++) {
        t[i][j] = Float.MAX_VALUE;
      }
    }
    
    //tags, outsides to O(utside) (middle overwritten with F)
    for(int i=0;i<tag.length;i++) {
      for(int j=0;j<tag[0].length;j++) {
        tag[i][j] = 'O';
      }
    }
    
    //middle with F(ar)
    for(int i=1;i<nz+1;i++) {
      for(int j=1;j<nx+1;j++) {
        tag[i][j] = 'F';
      }
    }
    //start point to A(ccepted)
    tag[ji(izs)][ji(ixs)] = 'A';
    
    //set the first time point to zero
    t[ji(izs)][ji(ixs)] = 0;
    
    //tag the start point & first close grid points
    nclose = 0;
    heap[nclose].hsiz = izs;
    heap[nclose].hsix = ixs;
    
    if(izs-1 >= 1) {
      tag[ji(izs-1)][ji(ixs)] = 'C';
      nclose++;
      heap[nclose].hsiz = izs-1;
      heap[nclose].hsix = ixs;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
    if(izs+1 <= nz) {
      tag[ji(izs+1)][ji(ixs)] = 'C';
      nclose++;
      heap[nclose].hsiz = izs+1;
      heap[nclose].hsix = ixs;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
    if(ixs-1 >= 1) {
      tag[ji(izs)][ji(ixs-1)] = 'C';
      nclose++;
      heap[nclose].hsiz = izs;
      heap[nclose].hsix = ixs-1;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
    if(ixs+1 <= nx) {
      tag[ji(izs)][ji(ixs+1)] = 'C';
      nclose++;
      heap[nclose].hsiz = izs;
      heap[nclose].hsix = ixs+1;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }

    max_iclose = nclose;
    min_iclose = 1;
    iclose = 1;
    
  }
  
  float[][] solver() {
    
    //initialise things
    initialise();
    
    //do the calculation
    while(iclose>0){
      //check all close values, find the smallest
      iclose = checkMinC();  //if this falls through iclose remains at 0 so we can use this to detect the end of the calculation
      //check limits and calculate
      if((heap[iclose].hsiz < nz+1) && (heap[iclose].hsiz > 0)) {
        if((heap[iclose].hsix < nx+1) && (heap[iclose].hsix > 0)) {
          markNeighboursCandCalc(iclose);
        }
      }
    }
    
    //remap output (and check for missed points which we still have sometimes, somehow)
    for(int i=0;i<nz;i++) {
      for(int j=0;j<nx;j++) {
        tmap[i][j] = t[i+1][j+1];
        if(tmap[i][j] > 3.4E38) {
          println("max",i,j,t[i+1][j+1]);
          calculate(i,j);
          println("recalc",i,j,t[i+1][j+1]);
          tmap[i][j] = t[i+1][j+1];
        }
      }
    }
    
    return tmap;
  }
  
  int checkMinC() {
    int minI = 0;
    float minT = 0;
    boolean inited = false;
    
    //loop through heap range for close values
    for(int i=min_iclose;i<max_iclose;i++) {
      //check for the min value of t
      if(tag[ji(heap[i].hsiz)][ji(heap[i].hsix)] == 'C') {
        if(!inited) {
          minI = i;
          minT = t[ji(heap[i].hsiz)][ji(heap[i].hsix)];
          inited = true;
        } else {
          if(t[ji(heap[i].hsiz)][ji(heap[i].hsix)] < minT) {
            minT = t[ji(heap[i].hsiz)][ji(heap[i].hsix)];
            minI = i;
          }
        }
      }
    }
    
    if(minI == min_iclose) {
      //remove the lowest index if it was the minimum
      //  ==> this doesn't seem to cut the number of checks too much
      //  ==> there's probably a better way to do it
      min_iclose = minI+1;
    }
    
    //accept the minimum value
    tag[ji(heap[minI].hsiz)][ji(heap[minI].hsix)] = 'A';
    
    return minI;
  }
  
  void markNeighboursCandCalc(int index){
    int ppz = heap[index].hsiz;
    int ppx = heap[index].hsix;
    
    //if the neighbour of [iz][ix] is FAR set as close & calculate
    if(tag[ji(ppz-1)][ji(ppx)] == 'F') {
      nclose++;
      tag[ji(ppz-1)][ji(ppx)] = 'C';
      heap[nclose].hsiz = ppz-1;
      heap[nclose].hsix = ppx;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
    
    if(tag[ji(ppz+1)][ji(ppx)] == 'F') {
      nclose++;
      tag[ji(ppz+1)][ji(ppx)] = 'C';
      heap[nclose].hsiz = ppz+1;
      heap[nclose].hsix = ppx;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
    
    if(tag[ji(ppz)][ji(ppx-1)] == 'F') {
      nclose++;
      tag[ji(ppz)][ji(ppx-1)] = 'C';
      heap[nclose].hsiz = ppz;
      heap[nclose].hsix = ppx-1;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
           
    if(tag[ji(ppz)][ji(ppx+1)] == 'F') {
      nclose++;
      tag[ji(ppz)][ji(ppx+1)] = 'C';
      heap[nclose].hsiz = ppz;
      heap[nclose].hsix = ppx+1;
      calculate(heap[nclose].hsiz,heap[nclose].hsix);
    }
    
    max_iclose = nclose;
  }
  
  void calculate(int ppz, int ppx) {
    
    //forward or backward derivative
    if(t[ji(ppz+1)][ji(ppx)] < t[ji(ppz-1)][ji(ppx)]) {
      pz = -1/dz;
      tv = t[ji(ppz+1)][ji(ppx)];
      if(t[ji(ppz+2)][ji(ppx)] < t[ji(ppz+1)][ji(ppx)]){
        tv = (4*t[ji(ppz+1)][ji(ppx)]-t[ji(ppz+2)][ji(ppx)])/3;
        pz = -3/(2*dz);
      }
    } else {
      pz = 1/dz;
      tv = t[ji(ppz-1)][ji(ppx)];
      if(t[ji(ppz-2)][ji(ppx)] < t[ji(ppz-1)][ji(ppx)]) {
        tv = (4*t[ji(ppz-1)][ji(ppx)]-t[ji(ppz-2)][ji(ppx)])/3;
        pz = 3/(2*dz);
      }
    }
    
    if((ppz<=nz)&&(ppx+2<nx)) {
      if(t[ji(ppz)][ji(ppx+1)] < t[ji(ppz)][ji(ppx-1)]) {
        px = -1/dx;
        th = t[ji(ppz)][ji(ppx+1)];
        if(t[ji(ppz)][ji(ppx+2)] < t[ji(ppz)][ji(ppx+1)]) {
          th = (4*t[ji(ppz)][ji(ppx+1)]-t[ji(ppz)][ji(ppx+2)])/3;
          px = -3/(2*dx);
        }
      } else {
        px = 1/dx;
        th = t[ji(ppz)][ji(ppx-1)];
        if(t[ji(ppz)][ji(ppx-2)] < t[ji(ppz)][ji(ppx-1)]) {
          th = (4*t[ji(ppz)][ji(ppx-1)]-t[ji(ppz)][ji(ppx-2)])/3;
          px = 3/(2*dx);
        }
      }
    }
    
    //quadratic parameters
    a = sq(pz) + sq(px);
    b = -2*(pz*pz*tv + px*px*th);
    c = sq(pz*tv) + sq(px*th) - sq(slowness[ppz][ppx]);
    delta = sq(b) - 4*a*c;
    
    //isotropic eikonal solution
    twoside = Float.MAX_VALUE;
    if(delta > 0) twoside = (-b+sqrt(delta))/(2*a);
    onesidez = tv + slowness[ppz][ppx]/abs(pz);
    onesidex = th + slowness[ppz][ppx]/abs(px);
    
    //update the min time and tag as alive
    t[ji(ppz)][ji(ppx)] = min(twoside,onesidez,onesidex);
  }
  
  //workaround method to convert FORTRAN indices (that can be negative) to Java indices (that can't)
  // ==> Java arrays have been set up to be shifted from -1 up to 0 up
  //     but the inputs to the arrays still assumed we can have a -1 index
  //     so we have to convert -1 to 0
  private int ji(int fi) {
    return fi+1;
  }
  
  //inner class for the heap (was a type in the FORTRAN)
  class Heap_struc {
    int hsiz;
    int hsix;
    Heap_struc() {
    }
  }
  
}
