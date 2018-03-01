/**
* Model:        OrderOfExecution
* Author:       Stefan Mohr
* Description:  This model demonstrates the order of execution of different parts of a GAMA model.
* 
* TODO reflexA in SpeciesA and SpeciesB overwrites reflexA of BaseSpecies. Is there a notion of "super()" in GAMA?
*/
model OrderOfExecution


global
{
    int variable1 <- get_int("global.variable1 <- 1");
    int variable2 <- get_int("global.variable2 <- 1");
    file gridA <- get_dem("global.dem <- file('../includes/dem.asc');");

    /**
     * This function / action returns an int. It's a helper do be able to log initialization of species properties
     * (object variables)
     */
    int get_int (string msg)
    {
        write string(self) + ":" + msg;
        return 1;
    }

    /**
     * This function / action returns a DEM. It's a helper do be able to log initialization of species properties
     * (object variables)
     */
    file get_dem (string msg)
    {
        write string(self) + ":" + msg;
        return file("../includes/dem.asc");
    }

    init
    {
        write string(self) + ":" + "global.init()";
        write string(self) + ":" + "    creating BaseSpecies";
        create BaseSpecies number: 1;
        write string(self) + ":" + "    creating SpeciesA";
        create SpeciesA number: 1;
        write string(self) + ":" + "    creating SpeciesB";
        create SpeciesB number: 1;
        write string(self) + ":" + "END OF global.init()";
    }

    reflex check_stop_conditions
    {
        write string(self) + ":" + "global.check_stop_conditions() ---> cycle: " + cycle;

        // check pause / stop conditions
        if (cycle = 3)
        {
            do pause;
        }

    }

    //you should always keep you object variables together at the top, but just to demo that this is also initialized
    //right away before init is executed.
    int variable3 <- get_int("global.variable3 <- 1") update: get_int("global.variable3 <- 1 (in update!)");
    reflex reflexA
    {
        write string(self) + ":" + "global.reflexA";
    }

    reflex reflexB
    {
        write string(self) + ":" + "global.reflexB";
    }
}

/**
 * BaseSpecies is the parent for SpeciesA and SpeciesB. This is to demnostrate the order of initialization and execution
 * of initalizers when using type hierarchies.
 */
species BaseSpecies
{
    int variable1 <- get_int("BaseSpecies.variable1 <- 1");
    int variable2 <- get_int("BaseSpecies.variable2 <- 1");

    /**
     * This function / action returns an int. It's a helper do be able to log initialization of species properties
     * (object variables)
     */
    int get_int (string msg)
    {
        write string(self) + ":" + msg;
        return 1;
    }

    reflex reflexA
    {
        write string(self) + ":" + "BaseSpecies.reflexA";
    }

    init
    {
        write string(self) + ":" + "BaseSpecies.init()";
    }
}

species SpeciesA parent: BaseSpecies
{
    int variable3 <- get_int("SpeciesA.variable3 <- 1");
    init
    {
        write string(self) + ":" + "SpeciesA.init()";
    }

    reflex reflexA
    {
        write string(self) + ":" + "SpeciesA.reflexA";
    }

    reflex reflexB
    {
        write string(self) + ":" + "SpeciesA.reflexB";
    }

    aspect aspectA
    {
        write string(self) + ":" + "SpeciesA.aspectA";
    }

}

species SpeciesB parent: BaseSpecies
{
    int variable2 <- get_int("SpeciesB.variable2 <- 1 (THIS VAR SHADOWS THE ONE IN BaseSpecies!!!)");
    int variable3 <- get_int("SpeciesB.variable3 <- 1") update: get_int("SpeciesB.variable3 <- 1 (in update!)");
    
    init
    {
        write string(self) + ":" + "SpeciesB.init()";
    }

    reflex reflexA
    {
        write string(self) + ":" + "SpeciesB.reflexA";
    }

    reflex reflexB
    {
        write string(self) + ":" + "SpeciesB.reflexB";
    }

    aspect aspectA
    {
        write string(self) + ":" + "SpeciesB.aspectA";
    }
}

grid GridSpeciesA file: gridA
{
    int variable1 <- get_int("GridSpeciesA.variable1 <- 1");
    /**
     * This function / action returns an int. It's a helper do be able to log initialization of species properties
     * (object variables)
     */
    int get_int (string msg)
    {
        write string(self) + ":" + msg;
        return 1;
    }

    init
    {
        write string(self) + ":" + "GridSpeciesA.init";
    }

    reflex reflexA
    {
        write string(self) + ":" + "GridSpeciesA.reflexA";
    }
}

experiment OrderOfExecution type: gui
{
    string test
    {
        write string(self) + ": experiment.test()";
        return "foo";
    }

    output
    {
        monitor "monitor 1" value: world.get_int("experiment.monitor1 <- 1") refresh: every(2 # cycles);
        monitor "monitor 2" value: world.get_int("experiment.monitor2 <- 1") refresh: every(1 # cycles);
        monitor "monitor 3" value: world.variable1 refresh: every(1 # cycles);
        display name: "dummy" refresh: every(1 # cycles) type: opengl
        {
            grid GridSpeciesA lines: # black;
            species SpeciesA aspect: aspectA refresh: true;
            species SpeciesB aspect: aspectA refresh: true;
        }
    }
}
