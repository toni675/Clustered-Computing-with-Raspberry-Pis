#### matrix_mult_test.c ####

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void multiply_matrices(int *A, int *B, int *C, int N, int start_row, int end_row) {
    for (int i = start_row; i < end_row; i++) {
        for (int j = 0; j < N; j++) {
            C[i * N + j] = 0;
            for (int k = 0; k < N; k++) {
                C[i * N + j] += A[i * N + k] * B[k * N + j];
            }
        }
    }
}

int main(int argc, char *argv[]) {
    int rank, size, N;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc < 2) {
        if (rank == 0) fprintf(stderr, "❌ Log file path must be provided as an argument.\n");
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    const char *log_file = argv[1];

    if (rank == 0) {
        printf("📐 Enter matrix size (NxN): ");
        fflush(stdout);
        if (scanf("%d", &N) != 1 || N <= 0) {
            fprintf(stderr, "❌ Invalid matrix size.\n");
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
    printf("%d", N);
    }

    MPI_Bcast(&N, 1, MPI_INT, 0, MPI_COMM_WORLD);

    int *A = NULL, *B = NULL, *C = NULL;
    if (rank == 0) {
        A = malloc(N * N * sizeof(int));
        B = malloc(N * N * sizeof(int));
        C = malloc(N * N * sizeof(int));
        for (int i = 0; i < N * N; i++) {
            A[i] = 1;
            B[i] = 1;
        }
    } else {
        B = malloc(N * N * sizeof(int));
    }

    MPI_Bcast(B, N * N, MPI_INT, 0, MPI_COMM_WORLD);

    int rows_per_proc = N / size;
    int remainder = N % size;
    int start_row = (rank < remainder) ? rank * (rows_per_proc + 1) : rank * rows_per_proc + remainder;
    int end_row = start_row + (rank < remainder ? rows_per_proc + 1 : rows_per_proc);
    int local_rows = end_row - start_row;

    int *local_A = malloc(local_rows * N * sizeof(int));
    int *local_C = malloc(local_rows * N * sizeof(int));

    if (rank == 0) {
        for (int i = 1; i < size; i++) {
            int s = (i < remainder) ? i * (rows_per_proc + 1) : i * rows_per_proc + remainder;
            int e = s + (i < remainder ? rows_per_proc + 1 : rows_per_proc);
            MPI_Send(A + s * N, (e - s) * N, MPI_INT, i, 0, MPI_COMM_WORLD);
        }
        memcpy(local_A, A, local_rows * N * sizeof(int));
    } else {
        MPI_Recv(local_A, local_rows * N, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }

    multiply_matrices(local_A, B, local_C, N, 0, local_rows);

    if (rank == 0) {
        memcpy(C, local_C, local_rows * N * sizeof(int));
        for (int i = 1; i < size; i++) {
            int s = (i < remainder) ? i * (rows_per_proc + 1) : i * rows_per_proc + remainder;
            int e = s + (i < remainder ? rows_per_proc + 1 : rows_per_proc);
            MPI_Recv(C + s * N, (e - s) * N, MPI_INT, i, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }
    } else {
        MPI_Send(local_C, local_rows * N, MPI_INT, 0, 1, MPI_COMM_WORLD);
    }

    free(local_A);
    free(local_C);
    free(B);
    if (rank == 0) {
        free(A);
        free(C);
    }

    MPI_Finalize();
    return 0;
}
