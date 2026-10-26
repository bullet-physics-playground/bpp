/*
============================================================================
 Name        : maze.c
 Author      : OpenGL Red Book
 Date        : November 15, 2007
 Version     : 0.0.1
 Copyright   : Copyright(c) 2007
 Description : Angle of incidence and angle of relection analysis
 ============================================================================
 */

#include <GL/gl.h>
#include <GL/glut.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "randomlib.h" // Bourke's RNG
#include "randomlib.c" // WMS

#define DEBUG false

bool run_gui = false;
bool step_by_step = false;
char *p_filename;
char *p_filename_2;
int move_counter = 0; // WMS

bool line_of_sight_matrix[100][100];

/*	used to draw the agents			*/
GLUquadricObj *qobj;

/**
 * \struct Vector2f
 * \brief  Represents a vector in 2D space.
 */
typedef struct s_vec2f
{
        GLfloat x;
        GLfloat y;

} Vector2f;

// used to collect the number of visits / cell 
typedef struct s_cells
{
	Vector2f coords;
	unsigned int counter;
} Cell_visit_cnt;

Cell_visit_cnt cell_visit_cnt_array[100];

/**
 * \struct Agent
 * \brief  Represents a robot.
 */
typedef struct s_agent
{
        int id;

        Vector2f init_position;    		// agent deployment position
        Vector2f position;              // agent position vector
        Vector2f temp_position;			
        Vector2f previous_position;
        Vector2f velocity;              // agent velocity vector
        Vector2f prior_force;

        float heading;					// agent heading (radians)
        float temp_heading;
        float previous_heading;
        
        float radius;                   // agent size
        float mass;                     // agent mass

        GLfloat color[3];
        Vector2f *intersection_points;	// the intersection points between each sensor range and walls
        bool *intersection_flags;		// flag if an intersection for any of the sensors took place
        
} Agent;

typedef enum e_force_law
{
	NEWTONIAN,
    LENNARD_JONES,
    HOOKE,

} Force_Law;

typedef enum e_starting_positon
{
	corner,
	side,
} Starting_Position;

Starting_Position agent_starting_position = -1;

/**
 * \struct Parameters
 * \brief  Encapsulates the parameters used in this simulation
 */
typedef struct s_params
{
	int vertix_number;
	int sensor_number;
	int world_width;
	int world_height;
    int sim_speed_ms;
	int agent_number;
    float agent_radius;
    float agent_mass;
    float wall_mass;
    int wall_width;
    float R;
    float sensor_range;
    float response_range;
    float response_range_temp;	// store the initial value of the response range for later use
    float response_range_step;
    float response_range_max;
    
    unsigned int time_steps;
    unsigned int sampling_step;
    
    Force_Law agent_agent_force_law;
    Force_Law agent_wall_force_law;

    float max_V;    		// Maximum agent velocity
    float G;                // Gravitational force
    float p;                // power to which distance is raised to - Newton's law
    float k;				// spring constant - Hooke's law
    float friction;
    float step;
    
    float PI;
    
    unsigned int cell_number;
    unsigned int cell_size;
    
    int random_seed;
} Parameters;

typedef struct s_statistics
{
	unsigned int time_step;
	unsigned int counter;
	
} Statistics;

GLfloat agent_color[3] = { 65. / 255, 105. / 255 , 225. / 255  };	// royal blue
GLfloat wall_color[3]  = { 105. / 255, 105. / 255 , 105. / 255  };  // dim gray

Agent **agents 	    = NULL;
Vector2f  *maze	    = NULL;
float *sensor_angle = NULL;

Parameters params;
Statistics stats;
/*
long int rrandom (long int high)
{
  long random();
  return( random() % high + 1 );
}
*/
// Return a random real from (0.0 1.0).
double u01 ()
{
  //return( ( double )rrandom( 4095 ) / 4096.0 );
  return(RandomUniform());
}

bool change_starting_position(void);

/**
 * \fn int read_config_file( char *p_filename )
 * \brief parses configuration file
 * \param p_filename to configuration file name
 * \return 0 on success, -1 on failure
 */
int read_config_file( char *p_filename )
{
	int i;
	FILE *p_config;
	p_config = fopen( p_filename, "r" );
	
	if ( p_config != NULL )
	{
		char first_string[100];
		char second_string[100];
		
		// read the number of active sensors
		fscanf( p_config, "%100s%100s%*[^\n]", first_string, second_string);
		if ( strcmp( "sensor_number", first_string ) == 0 )
		{
			params.sensor_number = atoi( second_string );
		}
		else
		{
			printf( "WARNING: Unknown parameter [%s]\n", first_string );
		}
		
		// read the angles of the sensors
		if( params.sensor_number )
		{
			sensor_angle = ( float * ) calloc( params.sensor_number, sizeof( float ) );
			
			if( sensor_angle == NULL )
			{
				printf( "Error while allocating memory for sensor angle array!" );
				return EXIT_FAILURE;
			}

			for( i = 0; i < params.sensor_number; i++ )
			{
				fscanf( p_config, "%100s%*[^\n]", first_string );
				// convert from degrees to radians ( * params.PI / 180 )
				sensor_angle[i] = atof( first_string ) * 0.017453293;
			}
		}
				
		// read the remaining parameters		
		while( fscanf( p_config, "%100s%100s%*[^\n]", first_string, second_string ) != EOF )
		{
			if( strcmp( "world_width", first_string ) == 0 )
			{
				params.world_width = atoi( second_string );
			}
			else if( strcmp( "world_height", first_string ) == 0 )
			{
				params.world_height = atoi( second_string );
			}
			else if( strcmp( "sim_speed_ms", first_string ) == 0 )
			{
				params.sim_speed_ms = atoi( second_string );
			}
			else if( strcmp( "agent_number", first_string ) == 0 )
			{
				params.agent_number = atoi( second_string );
			}
			else if( strcmp( "agent_radius", first_string ) == 0 )
			{
				params.agent_radius = atof( second_string );
			}
			else if( strcmp( "agent_mass", first_string ) == 0 )
			{
				params.agent_mass = atof( second_string );
			}
			else if( strcmp( "wall_mass", first_string ) == 0 )
			{
				params.wall_mass = atof( second_string );
			}
			else if( strcmp( "wall_width", first_string ) == 0 )
			{
				params.wall_width = atoi( second_string );
			}
			else if( strcmp( "R", first_string ) == 0 )
			{
				params.R = atof( second_string );
			}
			else if( strcmp( "sensor_range", first_string ) == 0 )
			{
				params.sensor_range = atof( second_string );
			}
			else if( strcmp( "response_range", first_string ) == 0 )
			{
				params.response_range = params.response_range_temp = atof( second_string );
			}
			else if( strcmp( "agent_agent_force_law", first_string ) == 0 )
			{
				params.agent_agent_force_law = atoi( second_string );
			}
			else if( strcmp( "agent_wall_force_law", first_string ) == 0 )
			{
				params.agent_wall_force_law = atoi( second_string );
			}
			else if( strcmp( "max_V", first_string ) == 0 )
			{
				params.max_V = atof( second_string );
			}
			else if( strcmp( "G", first_string ) == 0 )
			{
				params.G = atof( second_string );
			}
			else if( strcmp( "p", first_string ) == 0 )
			{
				params.p = atof( second_string );
			}
			else if( strcmp( "k", first_string ) == 0 )
			{
				params.k = atof( second_string );
			}
			else if( strcmp( "friction", first_string ) == 0 )
			{
				params.friction = atof( second_string );
			}
			else if( strcmp( "step", first_string ) == 0 )
			{
				params.step = atof( second_string );
			}
			else if( strcmp( "PI", first_string ) == 0 )
			{
				params.PI = atof( second_string );
			}
			else if( strcmp( "response_range_step", first_string ) == 0 )
			{
				params.response_range_step = atof( second_string );
			}
			else if( strcmp( "response_range_max", first_string ) == 0 )
			{
				params.response_range_max = atof( second_string );
			}
			else if( strcmp( "time_steps", first_string ) == 0 )
			{
				params.time_steps = atoi( second_string );
			}
			else if( strcmp( "sampling_step", first_string ) == 0 )
			{
				params.sampling_step = atoi( second_string );
			}
			else
			{
				printf( "WARNING: Unknown parameter [%s]\n", first_string );
			}
		}
	}
	else
	{
		printf ("Error opening configuration file: \"%s\"!\n", p_filename );
		return EXIT_FAILURE;
	}
	
	fclose( p_config );
	
	return 0;
}

int read_environment_file( char *p_filename )
{
	int i;
	FILE *p_env;
	p_env = fopen( p_filename, "r" );
	
	if ( p_env != NULL )
	{
		char first_string[100];
		char second_string[100];

		// read the number of vertices in the maze
		fscanf( p_env, "%100s%100s%*[^\n]", first_string, second_string);
		if ( strcmp( "vertix_number", first_string ) == 0 )
		{
			params.vertix_number = atoi( second_string );
		}
		else
		{
			printf( "WARNING: Unknown parameter [%s]\n", first_string );
		}
		// read the vertices
		if( params.vertix_number )
		{
			maze = ( Vector2f * ) calloc( params.vertix_number, sizeof( Vector2f ) );
			
			if( maze == NULL )
			{
				printf( "Error while allocating memory for maze!" );
				return EXIT_FAILURE;
			}

			for( i = 0; i < params.vertix_number; i++ )
			{
				fscanf( p_env, "%100s%100s%*[^\n]", first_string, second_string );
				maze[i].x = atof( first_string );
				maze[i].y = atof( second_string );
			}
		}
		// read the number of cells in the maze
		fscanf( p_env, "%100s%100s%*[^\n]", first_string, second_string);
		if ( strcmp( "cell_number", first_string ) == 0 )
		{
			params.cell_number = atoi( second_string );
		}
		else
		{
			printf( "WARNING: Unknown parameter [%s]\n", first_string );
		}

		// populate the visit cell counter array
		for( i = 0; i < params.cell_number; i++ )
		{
			fscanf( p_env, "%100s%100s%*[^\n]", first_string, second_string );
			cell_visit_cnt_array[i].coords.x = atof( first_string );
			cell_visit_cnt_array[i].coords.y = atof( second_string );
			cell_visit_cnt_array[i].counter = 0;
		}

		// read the size of the cell
		fscanf( p_env, "%100s%100s%*[^\n]", first_string, second_string);
		if ( strcmp( "cell_size", first_string ) == 0 )
		{
			params.cell_size = atoi( second_string );
		}
		else
		{
			printf( "WARNING: Unknown parameter [%s]\n", first_string );
		}
	}
	else
	{
		printf ("Error opening environment configuration file: \"%s\"!\n", p_filename );
		return EXIT_FAILURE;
	}
	
	fclose( p_env );
	
	return 0;
}

Agent *create_agent( int id )
{
	unsigned int i = 0;
	Agent *agent = ( Agent * ) malloc( sizeof( Agent ) );
	
	if ( agent == NULL )
	{
		printf( "Error while allocating memory for an agent!" );
		return NULL;
	}
	
	agent->id = id;
	agent->heading = agent->temp_heading = agent->previous_heading = params.PI / 2;
	agent->mass = params.agent_mass;
	agent->radius = params.agent_radius;
	// WMS
	if (id == 0) {
	  agent->position.x = agent->temp_position.x = agent->previous_position.x = maze[0].x + 1;
	  agent->position.y = agent->temp_position.y = agent->previous_position.y = maze[0].y + 1;
	}
	else {
	  agent->position.x = agent->temp_position.x = agent->previous_position.x = maze[0].x + 6.0f;
	  agent->position.y = agent->temp_position.y = agent->previous_position.y = maze[0].y + 20.0f;
	}
	agent->velocity.x =  0.0f;
	agent->velocity.y =  0.0f;
	agent->prior_force.x =  0.0f;
	agent->prior_force.y =  0.0f;
	
	memcpy( agent->color, agent_color, 3 * sizeof( float ) );
	
	agent->intersection_points = ( Vector2f * ) calloc ( params.sensor_number, sizeof ( Vector2f ) );

	if ( agent->intersection_points == NULL )
	{
		printf( "Error while allocating memory for an agent's intersection points!" );
		return NULL;
	}

	agent->intersection_flags = ( bool * ) calloc ( params.sensor_number, sizeof ( bool ) );

	if ( agent->intersection_flags == NULL )
	{
		printf( "Error while allocating memory for an agent's intersection flags!" );
		return NULL;
	}
	
	for ( i = 0; i < params.sensor_number; i++)
	{
		agent->intersection_flags[ i ] = false;
	}

	if (DEBUG) {
	//*************************************************
	printf( "****** AGENT %d *****\n", agent->id );
	printf( "mass\t\t%f\n", agent->mass );
	printf( "radius\t\t%f\n", agent->radius );
	printf( "x\t\t%f\n", agent->position.x );
	printf( "y\t\t%f\n", agent->position.y );
	printf( "vx\t\t%f\n", agent->velocity.x );
	printf( "vy\t\t%f\n", agent->velocity.y );
	printf( "***********************" );
	printf( "\n\n" );
	//*************************************************
	}
	return agent;
}

int create_swarm( void )
{
	int i;

	/******************** Initialize agents ******************************/
	agents = ( Agent ** ) calloc( params.agent_number, sizeof( Agent * ) );
	
	if ( agents == NULL )
	{
		printf( "Error while allocating memory for agents array!" );
		return EXIT_FAILURE;
	}

	for ( i = 0; i < params.agent_number; i++ )
	{
		agents[i] = create_agent( i );
		
		if ( agents[i] == NULL )
		{
			printf( "Error while allocating memory for agent %d!", i );
			return EXIT_FAILURE;
		}
	}

	return 0;
}

void free_memory(void){
	int i;
	
	/** Free memory used by the swarm **/
	for( i = 0; i < params.agent_number; i++ )
	{
		if ( agents[i]->intersection_points != NULL ){
			free ( agents[i]->intersection_points );
		}
		if ( agents[i]->intersection_flags != NULL ){
			free ( agents[i]->intersection_flags );
		}
		if( agents[i] != NULL ) {
			free( agents[i] );
		}
	}

	if ( agents != NULL ) { free( agents ); }

	/** Free memory used by the maze **/

	if ( maze != NULL ) { free( maze ); }

	/** Free memory used by the sensor angle **/

	if ( sensor_angle != NULL ) { free( sensor_angle ); }

}

void draw_string( char *s )
{
	int i;

    for( i = 0; i < strlen( s ); i++ )
    {
    	glutBitmapCharacter( GLUT_BITMAP_8_BY_13, s[i] );
//    	glutBitmapCharacter( GLUT_BITMAP_HELVETICA_10, s[i] );	
//    	glutBitmapCharacter( GLUT_BITMAP_TIMES_ROMAN_10, s[i] );	
    }
}

bool intersect( const Vector2f m, const Vector2f n, const Vector2f o, const Vector2f p, Vector2f *intersect_point)
{
	float x1, y1, x2, y2, a1, b1, a2, b2;
	float dx, dy, da, db, s, t;
	bool intersect = false;
	x1 = m.x;
	y1 = m.y;
	x2 = n.x;
	y2 = n.y;
	a1 = o.x;
	b1 = o.y;
	a2 = p.x;
	b2 = p.y;
	if (DEBUG) {
		printf( "x1 = %.2f, y1 = %.2f\n", x1, y1 );
	    printf( "x2 = %.2f, y2 = %.2f\n", x2, y2 );
	    printf( "a1 = %.2f, b1 = %.2f\n", a1, b1 );
	    printf( "a2 = %.2f, b2 = %.2f\n", a2, b2 );
	}
	intersect_point->x = 0.0f;
	intersect_point->y = 0.0f;
	
	dx = x2 - x1;
	dy = y2 - y1;
	da = a2 - a1;
	db = b2 - b1;
	
	if ( ( da * dy - db * dx ) == 0 )
	{		
		// The segments are parallel.
		if (DEBUG) printf ( "\tLine segments are parallel.\n" );
		intersect = false;
	}
	else
	{
	    s = ( dx * ( b1 - y1 ) + dy * ( x1 - a1 ) ) / ( da * dy - db * dx );
	    t = ( da * ( y1 - b1 ) + db * ( a1 - x1 ) ) / ( db * dx - da * dy );
		if ( s >= 0.0 && s <= 1.0 && t >= 0.0 && t <= 1.0 )
		{
			intersect_point->x = x1 + t * dx;
			intersect_point->y = y1 + t * dy;
			// The segments intersect
			if (DEBUG) printf ( "\tLine segments intersect at: %.2f, %.2f\n", intersect_point->x, intersect_point->y );
			intersect = true;
		}
		else
		{
			// The segments do not intersect
			if (DEBUG) printf ( "\tLine segments do not intersect.\n" );
			intersect = false;
		}
	}	
    return intersect;
}

// Newtonian universal law of gravitaion
float calculate_newtonian_force(const float mass_1, const float mass_2, const float distance)
{
	return params.G * mass_1 * mass_2 / pow ( distance, params.p );
}


float calculate_lj_force( const float distance )
{
  //return pow( params.R, 1 ) / pow( distance, 2 ) - pow( params.R, 1.7) / pow( distance, 2.7);
  return 32.0 * pow( params.R, 1 ) / pow( distance, 2 ) - 32.0 * pow( params.R, 1.7) / pow( distance, 2.7);
}

float calculate_hooke_force( const float distance )
{
	return -params.k * ( params.R - distance );
}

int change_agent_number( int agent_number )
{
	int i;	
	int delta = agent_number - params.agent_number;
	
	if ( delta > 0 )
	{
		agents = ( Agent ** ) realloc( agents, agent_number * sizeof( Agent * ) );
		
		if ( agents == NULL )
		{
			printf( "Error while expanding memory for agents array!" );
			return EXIT_FAILURE;
		}
		
		for ( i = params.agent_number; i < agent_number; i++ )
		{
			agents[i] = create_agent( i );
		}
		
		params.agent_number = agent_number;
	}
	else if ( delta < 0 && abs( delta ) < params.agent_number )
	{
		agents = ( Agent ** ) realloc( agents, agent_number * sizeof( Agent * ) );
		
		if ( agents == NULL )
		{
			printf( "Error while shrinking memory for agents array!" );
			return EXIT_FAILURE;
		}
		
		params.agent_number = agent_number;
	}
	else if ( delta < 0 && abs( delta ) >= params.agent_number )
	{
		agents = ( Agent ** ) realloc( agents, sizeof( Agent * ) );
		
		if ( agents == NULL )
		{
			printf( "Error while shrinking memory for agents array!" );
			return EXIT_FAILURE;
		}
		
		params.agent_number = 1;
	}
	
	return EXIT_SUCCESS;
}

void impulse_agent(unsigned char a)
{
	Agent *agent = agents[a];
	agent->velocity.x = 0.5f * cos( 360 * u01() * 0.017453293 );
	agent->velocity.y = 0.5f * sin( 360 * u01() * 0.017453293 );
//	agent->velocity.x = 0.5f * cos( 50 * 0.017453293 );
//	agent->velocity.y = 0.5f * sin( 50 * 0.017453293 );

}

void move_agent( void )
{
	unsigned int a = 0, b = 0, s = 0, v = 0;
	Agent *agent = NULL, *agent_2 = NULL;
	Vector2f sensor_range_v, intersection_point;
	Vector2f wall_begin, wall_end;
	Vector2f wall_force, agent_force;
	float agent_net_force = 0.0f, wall_net_force = 0.0f;
	float distance_to_wall = 0.0f, distance_to_wall_old = 0.0f;
	float distance_to_agent_2 = 0.0f, angle_to_agent_2 = 0.0f;
	bool line_of_sight = true;
	// reset line of sight matrix
	for (a = 0; a < params.agent_number; a++)
		for (b = 0; b < params.agent_number; b++)
			line_of_sight_matrix[a][b] = false;
		
	//*****************For each agent************************
	
	for ( a = 0; a < params.agent_number; a++ ) 
	{
		//*****************Calculate agent-wall force************************

		agent = agents[a];

		wall_force.x = 0.0f;
		wall_force.y = 0.0f;
		
		// add a small attractive force forward
		// WMS
		//agent_force.x = 0.01f * cos( agent->heading );
		//agent_force.y = 0.01f * sin( agent->heading );
//		agent_force.x = 0.3 * agent->prior_force.x;
//		agent_force.y = 0.3 * agent->prior_force.y;
		agent_force.x = 0.0f;
		agent_force.y = 0.0f;
		
        //*****************For each sensor************************
		agent->intersection_flags[0] = false;
		
		// compute the end coordinate of the sensor range
		// params.sensor_range = 80 cm
		sensor_range_v.x = cos ( sensor_angle[s] + agent->heading ) * params.response_range + agent->position.x;
		sensor_range_v.y = sin ( sensor_angle[s] + agent->heading ) * params.response_range + agent->position.y;
	
		//*****************For each wall************************
		for ( v = 0; v < params.vertix_number; v++ )
		{
			wall_begin = maze[v];
	
			// maze array stores the unique vertices of the maze
			if (v == (params.vertix_number - 1))
			{
				wall_end = maze[0];
			}
			else 
			{
				wall_end = maze[v + 1];
			}	
	
			if ( intersect( agent->position, sensor_range_v, wall_begin, wall_end, &intersection_point ) )
			{
				// check if this sensor has already detected a wall
				if ( agent->intersection_flags[s] )
				{
					// check which wall is closer and keep the closest one
					distance_to_wall_old = sqrt ( pow ( agent->position.x - agent->intersection_points[s].x, 2 ) + 
											  pow ( agent->position.y - agent->intersection_points[s].y, 2 ) );
					distance_to_wall = sqrt ( pow ( agent->position.x - intersection_point.x, 2 ) + 
	       								  pow ( agent->position.y - intersection_point.y, 2 ) );
	       		
					if ( distance_to_wall < distance_to_wall_old )
					{
						agent->intersection_points[s].x = intersection_point.x;
						agent->intersection_points[s].y = intersection_point.y;
					}
				}
				else
				{
					agent->intersection_flags[s] = true;
		   			agent->intersection_points[s].x = intersection_point.x;
		   			agent->intersection_points[s].y = intersection_point.y;
				}
		   	}
		}

		move_counter++; // WMS
		//while (agent->intersection_flags[0])
		//while (agent->intersection_flags[0] || (move_counter == (int)(params.cell_size * 0.6)))
		while (agent->intersection_flags[0] || (move_counter == (int)(params.cell_size * 0.6)))
		{	    		
			agent->heading = u01() * params.PI * 2;
			move_counter = 0; //WMS

	        //*****************For each sensor************************
			agent->intersection_flags[0] = false;
			
			// compute the end coordinate of the sensor range
			// params.sensor_range = 80 cm
			sensor_range_v.x = cos ( sensor_angle[s] + agent->heading ) * params.response_range + agent->position.x;
			sensor_range_v.y = sin ( sensor_angle[s] + agent->heading ) * params.response_range + agent->position.y;
		
			//*****************For each wall************************
			for ( v = 0; v < params.vertix_number; v++ )
			{
				wall_begin = maze[v];
		
				// maze array stores the unique vertices of the maze
				if (v == (params.vertix_number - 1))
				{
					wall_end = maze[0];
				}
				else 
				{
					wall_end = maze[v + 1];
				}	
		
				if ( intersect( agent->position, sensor_range_v, wall_begin, wall_end, &intersection_point ) )
				{
					// check if this sensor has already detected a wall
					if ( agent->intersection_flags[s] )
					{
						// check which wall is closer and keep the closest one
						distance_to_wall_old = sqrt ( pow ( agent->position.x - agent->intersection_points[s].x, 2 ) + 
												  pow ( agent->position.y - agent->intersection_points[s].y, 2 ) );
						distance_to_wall = sqrt ( pow ( agent->position.x - intersection_point.x, 2 ) + 
		       								  pow ( agent->position.y - intersection_point.y, 2 ) );
		       		
						if ( distance_to_wall < distance_to_wall_old )
						{
							agent->intersection_points[s].x = intersection_point.x;
							agent->intersection_points[s].y = intersection_point.y;
						}
					}
					else
					{
						agent->intersection_flags[s] = true;
			   			agent->intersection_points[s].x = intersection_point.x;
			   			agent->intersection_points[s].y = intersection_point.y;
					}
			   	}
			}
		}
			    
        // update agent velocity vector
        agent->velocity.x = cos(agent->heading);
        agent->velocity.y = sin(agent->heading);
        
        // update agent position and heading
        agent->temp_position.x += agent->velocity.x;
        agent->temp_position.y += agent->velocity.y;
       	agent->temp_heading     = agent->heading; 
   	
//        printf ("*********\n");
	}
	
	// update all the agent positions at once
	for ( a = 0; a < params.agent_number; a++ ) 
	{
		agent = agents[a];
		agent->previous_position.x = agent->position.x;
		agent->previous_position.y = agent->position.y;
		agent->previous_heading    = agent->heading;
		agent->position.x = agent->temp_position.x;
		agent->position.y = agent->temp_position.y;
// comment the line below to prevent the heading from changing
		// WMS
		agent->heading  = agent->temp_heading;
	}
	
	++stats.time_step;
	
	glutPostRedisplay();
}

void write_cell_visit_cnt_array_to_file( void )
{
        int i;
    	// store the filename here	
    	char fn [50];
    	// store the starting position here
    	char temp_str[10];
    	if ( agent_starting_position == corner )
    	{
    		strcpy(temp_str, "corner");		
    	}
    	else if ( agent_starting_position == side )
    	{
    		strcpy(temp_str, "side");		
    	}
    	sprintf( fn, "cell_visit_counter_%d_%.2f_%s_%d.out", (int)params.cell_size, params.response_range, temp_str,
    			params.random_seed);
        FILE *p_cvca;
        // append to file
        p_cvca = fopen( fn, "a" );

        if ( p_cvca != NULL )
        {
        	// write the time step
        	fprintf(p_cvca, "%d\n", (int)stats.time_step);
        	// write the cell_visit_cnt_array
        	for (i = 0; i < params.cell_number; i++)
        	{
        		fprintf(p_cvca, "%d %d\n", i, (int)cell_visit_cnt_array[i].counter);
        	}
        }
        else
        {
        	printf( "Error opening output file: \"%s\"!\n", fn);
        }

        fclose( p_cvca );
}

void write_to_file( void )
{
	int i;
	// store the starting position here
	char temp_str[10];
	// store the filename here	
	char fn [50];
	if ( agent_starting_position == corner )
	{
		strcpy(temp_str, "corner");		
	}
	else if ( agent_starting_position == side )
	{
		strcpy(temp_str, "side");		
	}
	sprintf( fn, "cell_visit_counter_%d_%.2f_%s_%d.out", (int)params.cell_size, params.response_range, temp_str,
			params.random_seed);
	FILE *p_cvca;
	p_cvca = fopen( fn, "w" );

	if ( p_cvca != NULL )
	{
		// write some help
		fprintf(p_cvca, "total number of cells\ncell number\tx y coordinates of each cell's lower left corner\n");
		fprintf(p_cvca, "cell size\nsensor range\nstarting position of the agent\n");
		fprintf(p_cvca, "time step\ncell number\tnumber of visits\n");
      		
		// write the total number of cells
		fprintf(p_cvca, "%d\n", (int)params.cell_number);
		// write lower left corner of each cell
		for ( i = 0; i < params.cell_number; i++ )
		{
			fprintf(p_cvca, "%d\t%d\t%d\n", i,
					(int)cell_visit_cnt_array[i].coords.x, 
					(int)cell_visit_cnt_array[i].coords.y);
		}
		// write the size of the cell
		fprintf(p_cvca, "%d\n", (int)params.cell_size);
		// write the sensor response range
		fprintf(p_cvca, "%.2f\n", params.response_range);
		// write the agent starting position
		fprintf(p_cvca, "%d\t%d\n", (int)agents[0]->position.x, (int)agents[0]->position.y);
	}
	else
	{
		printf( "Error opening output file: \"%s\"!\n", fn);
	}
	fclose( p_cvca );
}


void print_cell_visit_cnt_array(void)
{
	unsigned int i = 0;
	for ( i = 0; i < params.cell_number; i++){
		printf("%d, %d\n", i, cell_visit_cnt_array[i].counter);
	}
}

// record the cell visits
void record_cell_visits(void)
{
	unsigned int i;
	float tx = agents[0]->position.x;
	float ty = agents[0]->position.y;
	for (i = params.cell_number - 1 ; i >= 0; i--)
	{
		if ( tx >= cell_visit_cnt_array[i].coords.x )
		{
			if ( ty >= cell_visit_cnt_array[i].coords.y )
			{
				cell_visit_cnt_array[i].counter++;
				break;
			}
		}
	}
	if (stats.time_step % params.sampling_step == 0)
	{
//		printf("\n%d\n", stats.time_step);
//		print_cell_visit_cnt_array();
		write_cell_visit_cnt_array_to_file();
	}
}

// adjust the respnse range
bool change_response_range( void )
{
	bool flag = false;
	float temp;
	// adjust the response range
	if ( params.response_range <= params.response_range_max - params.response_range_step)
	{
		// make sure the response range is not bigger than the cell size
		temp = params.response_range + params.response_range_step;
		if ( temp <= (float)params.cell_size )
		{
			params.response_range = temp;
			flag = true;			
		}
	}
	return flag;
}

int find_cell( float x, float y)
{
	int i, counter = -1;
	for ( i = 0; i < params.cell_number; i++ )
	{
		if ( x >= cell_visit_cnt_array[i].coords.x && x <= cell_visit_cnt_array[i].coords.x + (float)params.cell_size )
		{
			if ( y >= cell_visit_cnt_array[i].coords.y && y <= cell_visit_cnt_array[i].coords.y + (float)params.cell_size )
			{
				counter = i;
				break;
			}		
		}
	}
	return counter;
}

// adjust the starting position 
bool change_starting_position(void)
{
	int random_number;
	int temp = -1, temp_x, temp_y;
	bool return_flag = false;

//	printf("agent_starting_position = %d\n", (int)agent_starting_position);
	if ( (int)agent_starting_position < (int)side )
	{	
		agent_starting_position += 2;
//		printf("agent_starting_position = %d\n", (int)agent_starting_position);
		switch (agent_starting_position)
		{
		case corner:
			random_number = (int)((params.vertix_number - 1) * u01());
			temp = find_cell(maze[random_number].x, maze[random_number].y);
	    	if ( temp >= 0)
	    	{
	    		agents[0]->temp_position.x = agents[0]->position.x = agents[0]->previous_position.x = 
	    			cell_visit_cnt_array[temp].coords.x + (float)params.cell_size / 2;
	    		agents[0]->temp_position.y = agents[0]->position.y = agents[0]->previous_position.y =
	    			cell_visit_cnt_array[temp].coords.y + (float)params.cell_size / 2;
	    		printf("Init position set to corner: %d, %d\n", (int)agents[0]->position.x, (int)agents[0]->position.y);
	    	}
	    	else{
	    		printf("ERROR: Could not find a corner starting position.\n");
		    	exit( EXIT_FAILURE );
	    	}
			break;
		case side:
			random_number = (int)((params.vertix_number - 1) * u01());
			// find the half distance between this vertex and the next one
			// if the X is the same
			if ( maze[random_number].x == ( maze[(random_number + 1) % params.vertix_number].x ) )
			{
				if ( maze[random_number].y > maze[(random_number + 1) % params.vertix_number].y )
				{
					temp_y = ( maze[random_number].y - maze[(random_number + 1) % params.vertix_number].y ) / 2 +
							 maze[(random_number + 1) % params.vertix_number].y;
				}
				else
				{
					temp_y = ( maze[(random_number + 1) % params.vertix_number].y - maze[random_number].y ) / 2 +
							 maze[random_number].y;
				}
//	    		printf("%d, %d, %d\n", (int)random_number, (int)temp_y, (int)maze[random_number].x);
				temp = find_cell(maze[random_number].x, temp_y);
		    	if ( temp >= 0)
		    	{
		    		agents[0]->temp_position.x = agents[0]->position.x = agents[0]->previous_position.x = 
		    			cell_visit_cnt_array[temp].coords.x + params.cell_size / 2;
		    		agents[0]->temp_position.y = agents[0]->position.y = agents[0]->previous_position.y =
		    			cell_visit_cnt_array[temp].coords.y + params.cell_size / 2;
		    		printf("Init position set to side: %d, %d\n", (int)agents[0]->position.x, (int)agents[0]->position.y);
		    	}
		    	else{
		    		printf("ERROR 1: Could not find a side starting position.\n");
			    	exit( EXIT_FAILURE );
		    	}
			}
			// if Y is the same
			else
			{
				if ( maze[random_number].x > maze[(random_number + 1) % params.vertix_number].x )
				{
					temp_x = ( maze[random_number].x - maze[(random_number + 1) % params.vertix_number].x ) / 2 +
							 maze[(random_number + 1) % params.vertix_number].x;
				}
				else
				{
					temp_x = ( maze[(random_number + 1) % params.vertix_number].x - maze[random_number].x ) / 2 +
							 maze[random_number].x;
				}
// 	    		printf("%d, %d, %d\n", (int)random_number, (int)temp_x, (int)maze[random_number].y);
				temp = find_cell(temp_x, maze[random_number].y);
		    	if ( temp >= 0)
		    	{
		    		agents[0]->temp_position.x = agents[0]->position.x = agents[0]->previous_position.x = 
		    			cell_visit_cnt_array[temp].coords.x + params.cell_size / 2;
		    		agents[0]->temp_position.y = agents[0]->position.y = agents[0]->previous_position.y =
		    			cell_visit_cnt_array[temp].coords.y + params.cell_size / 2;
		    		printf("Init position set to side: %d, %d\n", (int)agents[0]->position.x, (int)agents[0]->position.y);
		    	}
		    	else{
		    		printf("ERROR 2: Could not find a side starting position.\n");
			    	exit( EXIT_FAILURE );
		    	}
				
			}
			break;
		default:
			break;
		}
		return_flag = true;
	}
	
	return return_flag;
}

void run_GUI(int time)
{
	int i;
	if ( run_gui )
	{		
		move_agent();
		record_cell_visits();		
		if ( stats.time_step % params.time_steps == 0 )
		{
			// if no more response ranges
			if ( !change_response_range() )
			{				
				
 				// if no more starting positions
//				if ( !change_starting_position() )
//				{				
					exit( EXIT_SUCCESS );
//				}
				// reset sensor response range
//				params.response_range = params.response_range_temp;
//				stats.counter = 0;
			}
			printf("\t%d\n", stats.counter++);
			stats.time_step = 0;
			// reset the counter array
			for( i = 0; i < params.cell_number; i++ )
			{
				cell_visit_cnt_array[i].counter = 0;
			}
			write_to_file();
		}
		
		if ( step_by_step )
		{
			run_gui = false;
		}
	}
	glutPostRedisplay();
	glutTimerFunc( params.sim_speed_ms, run_GUI, stats.time_step );
}

void display_maze(void)
{
    /* draw the maze as a line loop		*/
    glColor3fv( wall_color );
    glLineWidth( params.wall_width );

    glDrawArrays( GL_LINE_LOOP, 0, params.vertix_number);

}

void display_agent( Agent *agent )
{
	unsigned char i = 0;
	float x_offset = 0.0f, y_offset = 0.0f;

	glLineWidth( 3.0 );
	glColor3f( 1.0f, 99.f / 255 , 71.f / 255 );		// tomato
	 		
	for ( i = 0; i < params.sensor_number; i++)
	{
		// compute the offsets to display the sensors' range
	    x_offset = cos( agent->previous_heading + sensor_angle[i] ) * params.sensor_range;
	    y_offset = sin( agent->previous_heading + sensor_angle[i] ) * params.sensor_range;
	 
	    // draw the range of the sensor
		glBegin(GL_LINES);
		   glVertex2f( agent->previous_position.x + x_offset,
				       agent->previous_position.y + y_offset );
		   glVertex2f( agent->previous_position.x,
				       agent->previous_position.y );
		glEnd();

	}
		
	// draw the sensor range intersection points
	glColor3f( 1.0f, 0.0f , 0.0f );	// red

	for ( i = 0; i < params.sensor_number; i++ )
	{
		if ( agent->intersection_flags[i] )
		{
		    glPushMatrix();
				glTranslatef( agent->intersection_points[i].x,
							  agent->intersection_points[i].y, 0.0f );
		    	gluDisk( qobj, 0.0, 3.0, 10, 1 );
	        glPopMatrix();
		}
	}
		
	// draw the agent
	glColor3fv( agent->color );
	
    // make a copy of the top matrix and place it on top
    glPushMatrix();
    	glTranslatef( agent->previous_position.x, agent->previous_position.y, 0.0 );
    	gluDisk( qobj, 0.0, agent->radius, 10, 1 );
    // destory the copy on top
    glPopMatrix();

	// draw the dot to show the current heading of the agent
    glColor3f( 0.0f, 0.0f , 0.0f );		// black

	// compute the offsets to display the heading mark
    x_offset = cos( agent->previous_heading ) * agent->radius;
    y_offset = sin( agent->previous_heading ) * agent->radius;
 
    // make a copy to the top matrix and place it on top
    glPushMatrix();
    	glTranslatef( agent->previous_position.x + x_offset,
    				  agent->previous_position.y + y_offset, 0.0 );
    	gluDisk( qobj, 0.0, agent->radius / 2.0f, 6, 1 );
    // destory the copy on top
    glPopMatrix();
    
	glutPostRedisplay();
}

void display_rectangle(void)
{
    glColor3f( 1.0f, 1.0f , 1.0f );	
	glBegin(GL_POLYGON);
	   glVertex2f(-65.0, 385.0);
	   glVertex2f(-65.0, 460.0);
	   glVertex2f(130.0, 460.0);
	   glVertex2f(130.0, 385.0);
	glEnd();
	glutPostRedisplay();

}

void display_line_of_sight( void )
{
	unsigned char a = 0, b = 0;
	float x_offset = 0.0f, y_offset = 0.0f;

	glLineWidth( 3.0 );
	glColor3f( 0.0f, 119.0f / 255 , 0.0f );		// green
	 		
	for ( a = 0; a < params.agent_number; a++)
	{
		for ( b = 0; b < params.agent_number; b++)
		{
			if ( line_of_sight_matrix[a][b] )
			{
			    // draw the line of sight
				glBegin(GL_LINES);
				   glVertex2f( agents[a]->previous_position.x,
						       agents[a]->previous_position.y);
				   glVertex2f( agents[b]->previous_position.x,
						       agents[b]->previous_position.y );
				glEnd();
		
			}
		}
	}
		    
	glutPostRedisplay();
}	

void display_params(void)
{
	char label[100];
	
//    glColor3f( 0.7f, 0.0f, 0.6f );
    glColor3f( 0.0f, 0.0f, 1.0f );

    glRasterPos2i( -190, 450 );
    sprintf( label, "Time step        : %d", stats.time_step );
    draw_string( label );

    glRasterPos2i( -190, 440 );
    sprintf( label, "Number of agents : %d", params.agent_number );
    draw_string( label );

    glRasterPos2i( -190, 430 );
    sprintf( label, "Agent %d heading  : %.2f deg", agents[0]->id, agents[0]->heading * ( 180 / params.PI ) );
    draw_string( label );

    glRasterPos2i( -190, 420 );
    sprintf( label, "Agent %d position : x = %6.2f px, y = %6.2f px", agents[0]->id, agents[0]->position.x, agents[0]->position.y );
    draw_string( label );

    glRasterPos2i( -190, 410 );
    sprintf( label, "Simulation speed : %d ms / time step", params.sim_speed_ms );
    draw_string( label );

    glRasterPos2i( -190, 400 );
    sprintf( label, "Sensor range     : %.1f px", params.sensor_range );
    draw_string( label );

    glRasterPos2i( -190, 390 );
    sprintf( label, "Response range   : %.1f px", params.response_range );
    draw_string( label );

    glutPostRedisplay();
}

void display_legend(void)
{
	char label[100];
	
//    glColor3f( 0.7f, 0.0f, 0.6f );
    glColor3f( 0.0f, 0.0f, 1.0f );

    glRasterPos2i( -200, -80 );
    sprintf( label, "Legend:" );
    draw_string( label );

    glRasterPos2i( -190, -90 );
    sprintf( label, "R/r       - reset" );
    draw_string( label );

    glRasterPos2i( -190, -100 );
    sprintf( label, "ESC/Q/q   - quit" );
    draw_string( label );

    glRasterPos2i( -190, -110 );
    sprintf( label, "SPACE/S/s - pause/unpause" );
    draw_string( label );

    glRasterPos2i( -190, -120 );
    sprintf( label, ".         - step by step" );
    draw_string( label );

    glRasterPos2i( -190, -130 );
    sprintf( label, "LEFT/RIGHT- decrease/increase response range" );
    draw_string( label );

    glRasterPos2i( -190, -140 );
    sprintf( label, "UP/DOWN   - decrease/increase simulation speed" );
    draw_string( label );

    glRasterPos2i( 130, -90 );
    sprintf( label, "PGUP/PGDOWN - increase/decrease agents" );
    draw_string( label );
    
    glutPostRedisplay();
}

void display(void)
{
	int i;
	/*  clear all pixels				*/
    glClear( GL_COLOR_BUFFER_BIT );

	display_maze();
	display_line_of_sight();
	display_legend();
	if (stats.time_step == 0)
	{
		glClear( GL_COLOR_BUFFER_BIT );
		display_maze();
		display_legend();
	}
	/*	display the swarm		*/
	for ( i = 0; i < params.agent_number; i++ )
	{
			display_agent(agents[i]);
	}

	display_rectangle();
	display_params();
	glutSwapBuffers();
}

void reset_statistics( void ){
	
	stats.time_step = 0;
	
}

int reset_simulation(void)
{
	free_memory();
	reset_statistics();	

	// Initialize simulation parameters to sane defaults,
	// in case some information is missing from config file
	params.vertix_number = 0;
	params.world_width = 800;
	params.world_height = 600;
	params.sim_speed_ms = 10;
	params.agent_number = 100;
	params.agent_radius = 6.0;
	params.agent_mass = 1.0;
	params.wall_mass = 1.0;
	params.wall_width = 2;
	params.R = 50.0f;
	params.sensor_range = 1.5f;
	params.agent_agent_force_law = 0;
	params.agent_wall_force_law = 0;
	params.max_V = 0.5f;
	params.G = 1000.0f;
	params.p = 2.0f;
	params.friction = 1.0f;
	params.cell_size = 20;
	
	// Read in simulation parameters from config file
	if ( read_config_file( p_filename ) != 0 )
	{
		return EXIT_FAILURE;
	}
	
	// create swarm
	if ( create_swarm() != 0 )
	{ 
		return EXIT_FAILURE;
	}
	
    // give an impulse to the agent
    impulse_agent(0);
	/*  clear all pixels				*/
    glClear( GL_COLOR_BUFFER_BIT );

	return 0;
}

void print_parameters(void){
	int i;
	
	/*****************************************************************/
	printf( "vertix_number = %d\n", params.vertix_number );
	for ( i = 0; i < params.vertix_number; i++ )
	{
		printf("%.2f\t%.2f\n", maze[i].x, maze[i].y);
	}
	printf( "sensor_number = %d\n", params.sensor_number );
	for ( i = 0; i < params.sensor_number; i++ )
	{
		printf("%.2f\n", sensor_angle[i]);
	}
	printf( "world_width = %d\n", params.world_width );
	printf( "world_height = %d\n", params.world_height );
	printf( "sim_speed_ms = %d\n", params.sim_speed_ms );
	printf( "agent_number = %d\n", params.agent_number );
	printf( "agent_radius = %.2f\n", params.agent_radius );
	printf( "agent_mass = %.2f\n", params.agent_mass );
	printf( "wall_mass = %.2f\n", params.wall_mass );
	printf( "wall_width = %d\n", params.wall_width );
	printf( "R = %.2f\n", params.R );
	printf( "sensor_range = %.2f\n", params.sensor_range );
	printf( "agent_agent_force_law = %d\n", params.agent_agent_force_law );
	printf( "agent_wall_force_law = %d\n", params.agent_wall_force_law );
	printf( "max_V = %.2f\n", params.max_V );
	printf( "G = %.2f\n", params.G );
	printf( "p = %.2f\n", params.p );
	/*****************************************************************/

}

void print_cell_coordinates(void)
{
	unsigned int i = 0;
	printf("cell side length: %d\n", (int)params.cell_size);
	printf("cell number: (lower left corner), (upper right corner)\n");
	for ( i = 0; i < params.cell_number; i++){
		printf("cell %d: (%3d, %3d), (%3d, %3d)\n", i,
				(int)cell_visit_cnt_array[i].coords.x, 
				(int)cell_visit_cnt_array[i].coords.y,
				(int)( cell_visit_cnt_array[i].coords.x + (float)params.cell_size ),
				(int)( cell_visit_cnt_array[i].coords.y + (float)params.cell_size ));
	}
	printf("\n");
}

int init_simulation(void)
{
	// Initialize simulation parameters to sane defaults,
	// in case some information is missing from config file
	params.vertix_number = 0;
	params.world_width = 800;
	params.world_height = 600;
	params.sim_speed_ms = 10;
	params.agent_number = 100;
	params.agent_radius = 6.0;
	params.agent_mass = 1.0;
	params.wall_mass = 1.0;
	params.wall_width = 2;
	params.R = 50.0f;
	params.sensor_range = 1.5f;
	params.agent_agent_force_law = 0;
	params.agent_wall_force_law = 0;
	params.response_range_step = 1.0;
	params.response_range_max = 5.0;
	params.max_V = 0.5f;
	params.G = 1000.0f;
	params.p = 2.0f;
	params.friction = 1.0f;

	params.cell_size = 20;
	
	// Read in simulation parameters from config file
	if ( read_config_file( p_filename ) != 0 )
	{
		return EXIT_FAILURE;
	}
	
	// Read in environment configuration from config file
	if ( read_environment_file( p_filename_2 ) != 0 )
	{
		return EXIT_FAILURE;
	}

	stats.time_step = 0;
	
	// create swarm
	if ( create_swarm() != 0 )
	{ 
		return EXIT_FAILURE;
	}

    change_starting_position();
    
	if ( DEBUG ) print_parameters();
	if ( DEBUG ) print_cell_coordinates();
	write_to_file();
	
	stats.counter = 0;
	
	return 0;
}

void init_graphics(void)
{
    // better if this is reused
    qobj = gluNewQuadric();

	/*  select clearing(background) color       */
    glClearColor( 1.0f, 1.0f, 1.0f, 1.0f );

    /*  initialize viewing values  				*/
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glOrtho( -200.0, 420.0, -150.0, 470.0, -1.0, 1.0 );

    /* enable antialiasing for lines			*/
    glEnable( GL_LINE_SMOOTH );
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glHint( GL_LINE_SMOOTH_HINT, GL_DONT_CARE );

    /* enable antialiasing for points			*/
//    glEnable( GL_POINT_SMOOTH );
//    glHint( GL_POINT_SMOOTH_HINT, GL_DONT_CARE );

    /* enable vertex array for the maze			*/
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer (2, GL_FLOAT, 0, maze);

}

void keyboard_normal(unsigned char key, int x, int y)
{
	switch( key )
	{
	case '.':
		step_by_step = !step_by_step;
		run_gui = true;
		break;
	// reset simulation
	case 'r':
	case 'R':
	    reset_simulation();
		run_gui = false;
		break;
	case 's':
	case 'S':
	case 32:	/* Space Key	*/
		run_gui = !run_gui;
		break;
	case 'q':
	case 27:  /*  Escape Key  */
	case 'Q':
		print_cell_visit_cnt_array();
//	   	write_cell_visit_cnt_array_to_file();
		free_memory();
		exit( EXIT_SUCCESS );
    	break;
	default:
		break;
    }
	
	glutPostRedisplay();
}

void keyboard_special( int key, int x, int y )
{
	// NOTE: escape, backspace, and delete keys are generated as an ASCII character
	switch( key )
	{
	case GLUT_KEY_UP:
		if ( params.sim_speed_ms  < 100 ) params.sim_speed_ms++;
		else if ( params.sim_speed_ms  < 1000 ) params.sim_speed_ms += 10;
		break;
	case GLUT_KEY_DOWN:
		if ( params.sim_speed_ms  > 100 ) params.sim_speed_ms -= 10;
		else if ( params.sim_speed_ms > 0 ) params.sim_speed_ms--;
		break;
	case GLUT_KEY_RIGHT:
		if ( params.response_range  < params.sensor_range) params.response_range++;
		break;
	case GLUT_KEY_LEFT:
		if ( params.response_range  > 1 ) params.response_range--;
		break;
	case GLUT_KEY_PAGE_UP:
		if ( params.agent_number < 100 ) {
			if ( change_agent_number( params.agent_number + 1 ) != EXIT_SUCCESS ) { exit( EXIT_FAILURE ); }
		}
		break;
	case GLUT_KEY_PAGE_DOWN:
		if ( params.agent_number > 1) {
			if ( change_agent_number( params.agent_number - 1 ) != EXIT_SUCCESS ) { exit( EXIT_FAILURE ); }
		}
		break;
	default:
		break;
    }
	glutPostRedisplay();
}

/* 
 *  Declare initial window size, position, and display mode
 * (single buffer and RGBA).  Open window with "hello"
 *  in its title bar.  Call initialization routines.
 *  Register callback function to display graphics.
 *  Enter main loop and process events.
 */
int main( int argc, char** argv )
{
    params.random_seed = time( NULL );
    //srandom( params.random_seed );
    RandomInitialise(1, params.random_seed); // WMS

//    printf ("%d\n", params.random_seed);
	if ( argc == 1 )
	{
		printf( "usage: %s configuration_filename environment_configuration_filename\n", argv[0] );
		return EXIT_FAILURE;
	}
	
	p_filename = argv[1];
	p_filename_2 = argv[2]; 

	if ( init_simulation() != 0 )
	{
		return EXIT_FAILURE;
	}

    glutInit( &argc, argv );
    glutInitDisplayMode( GLUT_DOUBLE | GLUT_RGB );

    glutInitWindowSize( params.world_width, params.world_height ); 
//    glutInitWindowSize( 400, 1 ); 

    glutInitWindowPosition( 250, 0 );

    //WMS GRAPHICS
    glutCreateWindow( "Linear formations - OpenGL" );
    ////    glutCreateWindow( "Linear formations - No Graphics" );
   
    init_graphics();
   
    // WMS
    // uncomment the next line to have graphics
    glutDisplayFunc( display ); 

    // comment the next three lines when no graphics is desired

    glutKeyboardFunc( keyboard_normal );
    glutSpecialFunc( keyboard_special );

    // give an impulse to the agent
    impulse_agent(0);
    
    // start the simulatin immediately
    run_gui = !run_gui;
    
    glutTimerFunc( params.sim_speed_ms, run_GUI, stats.time_step );
    glutMainLoop();
    
    free_memory();
    
    return 0;   /* ISO C requires main to return int. */
}
